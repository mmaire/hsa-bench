function queue

% some defines
cntrRank = 0;
mstrRank = 1;
workerQueueDepth = 3;
exitTag = 0;
local = 0;
waitTime = .1;
updateTime = 5;

% Create communicator
MPI_Init;
global MPI_COMM_WORLD;
comm = MPI_COMM_WORLD;
commSize = MPI_Comm_size(comm);
myRank = MPI_Comm_rank(comm);
nWorker = commSize - 2;
updated = clock;
active = 1;

% naming of job files
jobDir = comm.machine_db.dir{1,comm.machine_id(1,mstrRank+1)};
jobName = @(jid,type) sprintf('%s/jobs%s/job%06i.mat',jobDir,type,jid);

% run master or worker code
machine=comm.machine_db.machine{comm.machine_id(myRank+1)};
disp(['Rank: ' num2str(myRank) '  [' machine ']']);
if( commSize<=2 ), disp('Cannot be run with only one process'); exit; end
if( myRank==cntrRank ), if(local), return; else exit; end; end
if( myRank==mstrRank ), master(); else worker(); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function master()
    % jobQueue = [jid, priority, status, time0, time1]
    % status=0: unassigned, status=-1: complete, status>0 worker
    jobQueue=zeros(0,5); workerLoad=zeros(1,nWorker);
    nextJob = 1; % next available job index (start after exitTag)
    while 1
      %%% probe disk for new msgs (slow)
      if( active<2 || etime(updated,clock)>updateTime )
        [ranks tags]=MPI_Probe('*','*',comm); updated=clock;
        [tags,order]=sort(tags); ranks=ranks(order);
      end
      
      %%% process communication messages from controller first
      locs = find(ranks==cntrRank);
      if( ~isempty(locs) )
        l=locs(1); tag=tags(l); tags(l)=[]; ranks(l)=[];
        [cmd cmdArgs] = MPI_Recv(cntrRank,tag,comm);
        switch cmd
          case 'closeQueue'
            % exit after sending to workers (can't use broadcast)
            for i=1:nWorker, MPI_Send(mstrRank+i,exitTag,comm,1); end
            fprintf('Exiting at %s\n',datestr(now)); exit;
            
          case 'jobGetIds'
            % get n job ids for communication purposes
            n=cmdArgs.n; jids=nextJob+(0:n-1); nextJob=nextJob+n;
            MPI_Send( cntrRank, tag, comm, jids );
            fprintf('Returned %i jids at %s\n',n,datestr(now));
            
          case 'jobsAdd'
            % perform sorted insert into jobQueue according to priority
            n = length(cmdArgs.jids);
            for j=1:n
              jid=cmdArgs.jids(j); priority=cmdArgs.priority(j);
              q=[jid priority 0 0 0]; [v,idx]=max(jobQueue(:,2)<priority);
              if(isempty(v)||v==0), idx=size(jobQueue,1)+1; end %add to end
              jobQueue = [jobQueue(1:idx-1,:); q; jobQueue(idx:end,:)];
              %fprintf('Added job %i to queue location %i\n',jid,idx);
            end
            fprintf('Added %i jids at %s\n',n,datestr(now));
            
          case 'jobRemove'
            % Remove jobs with given jids from queue if not complete.
            [disc,jobIds] = ismember(cmdArgs.jids,jobQueue(:,1));
            jobIds=jobIds(jobIds>0); jobIds=jobIds(jobQueue(jobIds,3)==0);
            for jid=jobQueue(jobIds,1)', delete(jobName(jid,'Todo')); end
            jobQueue(jobIds,:) = [];
            fprintf('Removed %d un-ran jobs from queue at %s\n', ...
              numel(jobIds), datestr(now));
            
          case 'jobTiming'
            % send back an array with rows = jid/overhead-time/job-time
            [disc,jobIds] = ismember(cmdArgs.jids,jobQueue(:,1));
            jobIds=jobIds(jobIds>0); timing=jobQueue(jobIds,[1 4 5]);
            MPI_Send( cntrRank, tag ,comm, timing );
            fprintf('Send back timing info at %s\n', datestr(now));
            
          case 'jobsClearOld'
            % remove all completed jobs from the job queue
            jobIds=jobQueue(:,3)==-1; jobQueue(jobIds,:) = [];
            fprintf('Cleared %d old jobs from queue at %s\n', ...
              numel(jobIds), datestr(now));
            
          otherwise
            % shouldn't get here, ignore cmd
            fprintf('Unkown controller comand %s',cmd);
        end
        active=2; continue;
      end
      
      %%% process one of the incoming worker messages
      locs = find(ranks>mstrRank);
      if( ~isempty(locs) )
        % receive the job from the worker
        fprintf('Incoming job: '); l=locs(1);
        worker=ranks(l); jid=tags(l); tags(l)=[]; ranks(l)=[];
        [jid timerInfo] = MPI_Recv(worker, jid, comm);
        % update queue since job finished
        workerLoad(worker-1) = workerLoad(worker-1)-1;
        jobId = find(jobQueue(:,1)==jid);
        jobQueue(jobId,3)=-1; jobQueue(jobId,4:5)=timerInfo;
        fprintf('received job %d from worker %d at %s\n', ...
          jid, worker, datestr(now)); active=2; continue;
      end
      
      %%% assign a job from the job queue to a worker
      jobId = find(jobQueue(:,3)==0);
      if( ~isempty(jobId) && any(workerLoad<workerQueueDepth) )
        % get worker with lightest queue (+1 since workers start at rank=2)
        fprintf('Outgoing job: '); jobId=jobId(1); jid=jobQueue(jobId,1);
        [disc,worker]=min(workerLoad); worker=worker+1; %#ok<NASGU>
        workerLoad(worker-1)=workerLoad(worker-1)+1;
        jobQueue(jobId,3)=worker;
        % send job to worker
        MPI_Send( worker, jid, comm, jid );
        fprintf('sent job %d to worker %d at %s\n', ...
          jid, worker, datestr(now)); active=2; continue;
      end
      
      %%% no messages awaiting master
      if(active==1), fprintf('Nothing to do %s\n',datestr(now)); end
      if(active>0), active=active-1; end; pause(waitTime);
    end
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function worker()
    tic; % to record overhead
    while 1
      %%% probe disk for new msgs (slow)
      if( active<2 || etime(updated,clock)>updateTime )
        [ranks tags]=MPI_Probe(mstrRank,'*',comm);
        tags=sort(tags); updated=clock;
      end
      
      %%% exit flag received, so exit
      if( ismember(exitTag,tags) )
        MPI_Recv(mstrRank,exitTag,comm);
        fprintf('Exiting at %s\n',datestr(now)); exit;
      end
      
      %%% receive job from master
      if( ~isempty(tags) )
        % receive the jid and the actual job
        jid=tags(1); tags(1)=[]; jid=MPI_Recv(mstrRank,jid,comm);
        fprintf('Received job %6d at %s ... ',jid,datestr(now));
        nm=jobName(jid,'Todo'); job=load(nm); delete(nm);
        fnNm=job.fnNm; fnArg=job.fnArg; fnPth=job.fnPth;
        % run the job (temporarily add fnPth to path)
        if(~isempty(fnPth)), oldPath=path; addpath(fnPth); end
        tOverhead = toc; tic; err=''; out=0; %#ok<NASGU>
        try out=feval(fnNm,fnArg{:}); catch err1 %#ok<NASGU>
          err = struct( 'err',err1, 'time',now, 'jid',jid, ...
            'rank',myRank, 'machine',machine ); %#ok<NASGU>
          fprintf('%s failed %s ',fnNm,err1.message);
        end
        tRunJob=toc; tic; timerInfo=[tOverhead tRunJob];
        if(~isempty(fnPth)), rmpath(fnPth); addpath(oldPath); end
        % store results and notify master
        nm=jobName(jid,'Done'); save([nm '_writing'],'out','err');
        movefile([nm '_writing'],nm); % rename after writing complete
        MPI_Send(mstrRank,jid,comm,jid,timerInfo);
        clear('fnArg','fnNm','fnPth','out','err','timerInfo');
        fprintf('took %f sec\n', tRunJob); active=2; continue;
      end
      
      %%% no messages awaiting worker
      if(active==1), fprintf('Nothing to do %s\n',datestr(now)); end
      if(active>0), active=active-1; end; pause(waitTime);
    end
  end

end
