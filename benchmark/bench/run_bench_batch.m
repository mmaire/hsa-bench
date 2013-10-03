% Run batch benchmark jobs for dataset.
%
% run_bench_batch(dset_dir, [machine_list], [n_jobs])
%
% Input:
%    dset_dir           - main directory for dataset
%    machine_list       - machines on which to execute cluster jobs
%                         (if [] then only use current machine)
%    n_jobs             - max number of jobs to launch in parallel (default: 1)
function run_bench_batch(dset_dir, machine_list, n_jobs)
   % default arguments
   if ((nargin < 2)), machine_list = []; end
   if ((nargin < 3) || isempty(n_jobs)), n_jobs = 1; end
   % assemble directory names
   dir_im    = fullfile(dset_dir, 'images');
   dir_rtree = fullfile(dset_dir, 'groundtruth');
   dir_ucm   = fullfile(dset_dir, 'ucm');
   dir_bench = fullfile(dset_dir, 'bench');
   % scan dataset for images
   fnames = dir([dir_im filesep '*.jpg']);
   fnames = { fnames.name };
   % create benchmark directory if it does not exist
   if (~exist(dir_bench,'dir'))
      mkdir(dir_bench);
   end
   % assemble job list
   n_images = numel(fnames);
   jobs = cell([1 n_images]);
   for n = 1:n_images
      % get image filename parts
      [pathstr name extn] = fileparts(fnames{n});
      % assemble io info
      io.fname_im    = fullfile(dir_im,    [name '.jpg']);
      io.fname_rtree = fullfile(dir_rtree, [name '.ann']);
      io.fname_ucm   = fullfile(dir_ucm,   [name '_ucm.bmp']);
      io.fname_bench = fullfile(dir_bench, [name '.mat']);
      io.fname_error = fullfile(dir_bench, [name '_error.txt']);
      % store job arguments
      jobs{n} = { io };
   end
   %  local or cluster execution parameters
   if (isempty(machine_list))
      p_distr = {'type','local'};
   else
      p_distr = {'type','distr','pLaunch',{n_jobs+2,machine_list}};
   end
   % run jobs
   if (~isempty(jobs))
      fevalDistr('run_bench_job',jobs,p_distr{:});
   end
end
