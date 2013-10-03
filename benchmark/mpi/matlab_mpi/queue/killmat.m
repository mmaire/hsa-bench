function killmat(hostnames, prefix)
	if(nargin<2 ||isempty(prefix)), prefix='vision'; end
	numHosts=numel(hostnames);
	if isnumeric(hostnames)
		hostsToKill = cell(1,numHosts);
		for i=1:numHosts; hostsToKill{i}=[prefix num2str(hostnames(i))]; end;
	else; hostsToKill=hostnames; end;

	[s,u]=unix('echo $USER'); username=deblank(u); 
	for i=1:numHosts
		fprintf(1,'Killing %s''s matlab sessions on %s\n', username, hostsToKill{i});
		cmd = sprintf(['ssh %s "ps -U $USER -u $USER | ' ...
									 'grep MATLAB | cut -b1-5 | xargs kill" &'], hostsToKill{i});
	  unix(cmd);
	end

