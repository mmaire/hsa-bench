% Generate per-image visualization output for all images in dataset.
%
% run_vis_bench(dset_dir)
%
% Input:
%
%   dset_dir - main directory for dataset
function run_vis_bench(dset_dir)
   % assemble directory names
   dir_im    = fullfile(dset_dir, 'images');
   dir_rtree = fullfile(dset_dir, 'groundtruth');
   dir_ucm   = fullfile(dset_dir, 'ucm');
   dir_bench = fullfile(dset_dir, 'bench');
   dir_vis   = fullfile(dset_dir, 'vis');
   % scan dataset for images
   fnames = dir([dir_im filesep '*.jpg']);
   fnames = { fnames.name };
   % create visualization directory if it does not exist
   if (~exist(dir_vis,'dir'))
      mkdir(dir_vis);
   end
   % create visualization for each image
   n_images = numel(fnames);
   for n = 1:n_images
      % get image filename parts
      [pathstr name extn] = fileparts(fnames{n});
      % assemble filenames
      fname_im    = fullfile(dir_im,    [name '.jpg']);
      fname_rtree = fullfile(dir_rtree, [name '.ann']);
      fname_ucm   = fullfile(dir_ucm,   [name '_ucm.bmp']);
      fname_bench = fullfile(dir_bench, [name '.mat']);
      % assemble output directory name
      outdir = fullfile(dir_vis, name);
      % create output directory if it does not exist
      if (~exist(outdir,'dir'))
         mkdir(outdir);
      end
      % load data
      im    = load_im(fname_im);
      rtree = load_rtree(fname_rtree);
      ucm   = load_ucm(fname_ucm);
      % load benchmark results
      bench = load(fname_bench);
      bench = bench.bench;
      % create visualization
      vis_bench(im, rtree, ucm, bench, outdir);
   end
end
