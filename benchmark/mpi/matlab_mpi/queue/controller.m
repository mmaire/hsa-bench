function varargout = controller( command, varargin )

%%% internal state
persistent commDir tag
if(isempty(tag)),
  commDir = 'MatMPI'; % communication directory
  tag = 0;            % tags for communication
end

%%% evaluate command
varargout = cell(1,max(1,nargout)); nout=nargout;
switch command
  case 'launchQueue',   nout=0; launchQueue(varargin{:});
  case 'closeQueue',    nout=0; closeQueue(varargin{:});
  case 'jobAdd',        [varargout{:}] = jobAdd(varargin{:});
  case 'jobsAdd',       [varargout{:}] = jobsAdd(varargin{:});
  case 'jobProbe',      [varargout{:}] = jobProbe(varargin{:});
  case 'jobRecv',       [varargout{:}] = jobRecv(varargin{:});
  case 'jobRemove',     nout=0; jobRemove(varargin{:});
  case 'jobTiming',     [varargout{:}] = jobTiming(varargin{:});
  case 'jobsClearOld',  nout=0; jobsClearOld(varargin{:});
  otherwise, error(['unkown command:' command]);
end
if(nout==0), assert(nargout==0); varargout={}; end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   function masterAdd( host, prefix )
%   function masterAddLocal()
%   function [nids,hosts,pids] = masterList()
%   function masterKill()
%   function slavesAdd( host, prefix )
%   function slaveAddLocal( n )
%   function [nids,hosts,pids] = slavesList()
%   function slavesKill( nids )

  function launchQueue( n, machines, prefix )
    if(nargin<2), machines={}; end
    if(nargin<3), prefix='vision'; end
    if(isnumeric(machines))
      machines=int2str2(machines); m=length(machines);
      if(ischar(machines)), machines={machines}; m=1; end
      for i=1:m, machines{i}=[prefix machines{i}]; end
    end
    MPI_Abort; pause(2.0);
    MatMPI_Delete_all; pause(2.0);
    eval(MPI_Run('queue',n,machines)); pause(2.0);
    mkdir([commDir '/jobsTodo']);
    mkdir([commDir '/jobsDone']);
  end

  function closeQueue()
    tag=tag+1; MPI_Send0( tag, 'closeQueue', 1 );
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  function jid = jobAdd( fnNm, fnArg, varargin )
    jid = jobsAdd( 1, fnNm, {fnArg}, varargin{:} );
  end

  function jids = jobsAdd( n, fnNms, fnArgs, fnPths, priority )
    % Add a job to the queue, return job id (jid).
    if(nargin<4 ||isempty(fnPths)), fnPths=[]; end
    if(nargin<5 ||isempty(priority)), priority=0; end
    % make sure each input is repeated n times
    assert(iscell(fnArgs) && numel(fnArgs)==n);
    if(~iscell(fnNms)), fnNms=repmat({fnNms},1,n); end
    if(~iscell(fnPths)), fnPths=repmat({fnPths},1,n); end
    if(isscalar(priority)), priority=repmat(priority,1,n); end
    % Get n job ids for communication purposes.
    tag=tag+1; MPI_Send0( tag, 'jobGetIds', struct('n',n) );
    jids = MPI_Recv0( tag );
    % send actual jobs first
    for i=1:n
      fnNm=fnNms{i}; fnArg=fnArgs{i}; fnPth=fnPths{i}; %#ok<NASGU>
      nm=sprintf('%s/jobsTodo/job%06i.mat',commDir,jids(i));
      save(nm,'fnNm','fnArg','fnPth');
    end
    % send notification of jobs
    tag=tag+1; args=struct('jids',jids,'priority',priority);
    MPI_Send0( tag, 'jobsAdd', args );
  end

  function jids = jobProbe( jids )
    % Return list of available job results.
    pth=[commDir '/jobsDone']; touchNm = [pth '/touch.mat'];
    if(isunix), unix(['touch ' touchNm '; rm ' touchNm ';']); end
    msgs=dir([pth '/job*.mat']); n=length(msgs); jids1=zeros(n,1);
    for i=1:n, jids1(i)=sscanf(msgs(i).name,'job%d.mat'); end
    jids = intersect(jids1,jids);
  end

  function [out, err] = jobRecv( jid, warn )
    % Retrieve results of job (can only be called once).
    if(nargin<2 || isempty(warn)), warn=1; end;
    nm = sprintf('%s/jobsDone/job%06i.mat',commDir,jid);
    res=load(nm); out=res.out; err=res.err; delete(nm);
    if(~isempty(err) && warn)
      disp(['job failed: ' err.err.message]);
      fprintf('time=%f jid=%i rank=%i machine=%s\n',...
        err.time,err.jid,err.rank,err.machine);
      s=err.err.stack; for i=1:length(s), disp(s(i)); end
    end
  end

  function jobRemove( jids )
    % Ask to remove jobs with given jids from queue (if not complete).
    assert( all(mod(jids,10)==1) );
    tag=tag+1; MPI_Send0( tag, 'jobRemove', struct('jids',jids) );
  end

  function timing = jobTiming( jids )
    % fraction complete, timing 0/1/2, expected time
    tag=tag+1; MPI_Send0( tag, 'jobTiming', struct('jids',jids) );
    timing = MPI_Recv0( tag );
  end

  function jobsClearOld()
    % clear all previous job-related files/stucts/variables (no killing)
    tag=tag+1; MPI_Send0( tag, 'jobsClearOld', struct([]) );
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function MPI_Send0( tag, varargin )
    % Send message to master.
    bufferNm = MatMPI_file0(0,1,tag,'buffer');
    lockNm = MatMPI_file0(0,1,tag,'lock');
    save(bufferNm,'varargin'); % Save buf to file
    fclose(fopen(lockNm,'w')); % Create lock file
  end

  function varargout = MPI_Recv0( tag )
    % Receives message from master (non-locking).
    
    % Spin on lock file until it is created or timeout reached
    lockNm=MatMPI_file0(1,0,tag,'lock'); fid=fopen(lockNm,'r');
    touchNm = MatMPI_file0(0,0,tag,'touch');
    for i=1:250 % set number of spins here
      if( fid~=-1 ), break; end
      if(isunix), unix(['touch ' touchNm '; rm ' touchNm ';']); end
      pause(.1); fid=fopen(lockNm,'r');
    end
    if(fid==-1), error('MPI_Recv0: file not received!'); end;
    fclose(fid);
    
    % Read all data out of bufferNm
    bufferNm = MatMPI_file0(1,0,tag,'buffer');
    buf = load(bufferNm); varargout = buf.varargin;
    
    % Delete buffer and lock files
    delete(bufferNm); delete(lockNm);
  end

  function fNm = MatMPI_file0( src, dst, tag, type )
    % Create lock/buffer/touch file name
    assert(src==0 || src==1); assert(dst==0 || dst==1);
    fNm = [commDir filesep 'p' num2str(src) '_p' num2str(dst) ...
      '_t' num2str(tag) '_' type '.mat'];
  end
end
