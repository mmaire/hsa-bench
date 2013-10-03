% Run a job to compute benchmark for an image.
%
% flag = run_bench_job(io)
%
% Input:
%    io.                - specification of files on which to operate
%       fname_im        - image filename
%       fname_rtree     - region tree filename
%       fname_ucm       - ucm filename
%       fname_bench     - output benchmark file
%       fname_error     - output error log file
%
% Output:
%       flag            - true on successful completion
function flag = run_bench_job(io)
   flag = true;
   try
      % check whether to compute benchmark
      if (~exist(io.fname_bench,'file'))
         % load data
         im    = load_im(io.fname_im);
         rtree = load_rtree(io.fname_rtree);
         ucm   = load_ucm(io.fname_ucm);
         % compute benchmark
         bench = eval_boundary(im, rtree, ucm);
         % save benchmark
         save(io.fname_bench, 'bench');
      end
   catch
      flag = false;
      try
         % retrieve error message
         err = lasterror;
         % log error
         f = fopen(io.fname_error,'w');
         fprintf(f,'%s\n',err.message);
         fclose(f);
      catch
      end
   end
end
