% Queue test for distributed computing.
%
% Perform distributed array sum (sum each row using a slave node). Gather
% the results, then sum one final time using a slave node.

%%% toy data (m+1 resulting jobs)
tic; m=100; n=10000; A=randn(m,n);

%%% launch controller
controller('launchQueue',4);

%%% launch jobs for getting row sums
fnArgs=cell(1,m); for i=1:m, fnArgs{i}={A(i,:)}; end
jids = controller('jobsAdd',m,'sum',fnArgs);
fprintf(1,'Sent jobs...\n'); toc; tic;

%%% gather results from jobs for getting row sums
tid=ticStatus('Receiving jobs',[],1); m1=0; A1=zeros(m,1);
while 1
  tocStatus(tid,m1/m); jids1=controller('jobProbe',jids);
  if(isempty(jids1)), pause(.1); continue; end
  jid=jids1(1); l=find(jids==jid); A1(l)=controller('jobRecv',jid);
  m1=m1+1; if(m1==m), tocStatus(tid,1); break; end
end
timing = controller('jobTiming',jids);
controller('jobsClearOld');

%%% send final job of summing A1
jid = controller('jobAdd','sum',{A1});
while 1
  jid1 = controller('jobProbe',jid);
  if(isempty(jid1)), pause(.1); continue; end
  a = controller('jobRecv',jid); break;
end

%%% compare sum computed locally and on cluster
disp([a sum(A(:))]) % distibuted sum / local sum
controller('closeQueue'); toc;
