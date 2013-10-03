% Combine results of multiple per-image benchmarks into a summary benchmark.
%
% [bench_tot] = combine_bench(dset_dir, names)
%
% Input:
%    dset_dir           - main directory for dataset
%    names              - image names to summarize (default: all images)
%
% Output:
%    bench_tot.         - summary benchmark data
%       gt_num_bdry     - # of groundtruth boundary pixels
%       gt_num_bdry_fg  - # of groundtruth figure/ground boundary pixels
%       gt_num_bdry_op  - # of groundtruth object/part boundary pixels
%       gt_num_level    - # of groundtruth boundary pixels at each level
%
%       thresh          - thresholds at which counts are recorded
%
%       R_cnt_bdry      - # of gt boundary pixels recalled at each thresh
%       R_cnt_bdry_fg   - # of gt fig/ground pixels recalled at each thresh
%       R_cnt_bdry_op   - # of gt obj/part pixels recalled at each thresh
%       R_cnt_level     - # of gt pixels recalled at each thresh at each level
%
%       P_num_bdry      - # of machine boundary pixels declared at each thresh
%       P_cnt_bdry      - # of correct machine boundary pixels at each thresh
%
%       R               - recall (all boundaries) as a function of threshold
%       P               - precision (all boundaries) as a function of threshold
%       F               - F-measure as a function of threshold
%
%       bestT           - threshold for optimal boundary F-measure
%       bestR           - recall at optimal threshold
%       bestP           - precision at optimal threshold
%       bestF           - F-measure at optimal threshold
%
%       level_ucm_hist  - histogram counts for equally spaced ucm value bins at
%                         each level
%       level_bin_cntrs - bin centers for above histogram
function [bench_tot] = combine_bench(dset_dir, names)
   % assemble directory names
   dir_im    = fullfile(dset_dir, 'images');
   dir_bench = fullfile(dset_dir, 'bench');
   % default arguments
   if (nargin < 2)
      % scan dataset for images
      fnames = dir([dir_im filesep '*.jpg']);
      fnames = { fnames.name };
      % remove extension
      n_images = numel(fnames);
      names = cell([1 n_images]);
      for n = 1:n_images
         [pathstr name extn] = fileparts(fnames{n});
         names{n} = name;
      end
   end
   % create summary benchmark
   bench_tot = [];
   n_images = numel(names);
   for n = 1:n_images
      % load benchmark results
      fname_bench = fullfile(dir_bench, [names{n} '.mat']);
      b = load(fname_bench);
      b = b.bench;
      % update summary
      if (n == 1)
         % initialize summary
         bench_tot = rmfield(b, {'match_ucm', 'match_gt', 'level_ucm_vals'});
      else
         % update groundtruth boundary counts
         bench_tot.gt_num_bdry    = bench_tot.gt_num_bdry    + b.gt_num_bdry;
         bench_tot.gt_num_bdry_fg = bench_tot.gt_num_bdry_fg + b.gt_num_bdry_fg;
         bench_tot.gt_num_bdry_op = bench_tot.gt_num_bdry_op + b.gt_num_bdry_op;
         % update per-level groundtruth boundary counts
         n_levels_tot = numel(bench_tot.gt_num_level);
         n_levels_b   = numel(b.gt_num_level);
         n_levels = max(n_levels_tot, n_levels_b);
         gt_num_level = zeros([1 n_levels]);
         for l = 1:n_levels_tot
            gt_num_level(l) = gt_num_level(l) + bench_tot.gt_num_level(l);
         end
         for l = 1:n_levels_b
            gt_num_level(l) = gt_num_level(l) + b.gt_num_level(l);
         end
         bench_tot.gt_num_level = gt_num_level;
         % update counts of recalled pixels
         bench_tot.R_cnt_bdry    = bench_tot.R_cnt_bdry    + b.R_cnt_bdry;
         bench_tot.R_cnt_bdry_fg = bench_tot.R_cnt_bdry_fg + b.R_cnt_bdry_fg;
         bench_tot.R_cnt_bdry_op = bench_tot.R_cnt_bdry_op + b.R_cnt_bdry_op;
         % update per-level counts of recalled pixels
         n_thresh    = numel(bench_tot.thresh);
         R_cnt_level = zeros([n_thresh n_levels]);
         for l = 1:n_levels_tot
            R_cnt_level(:,l) = R_cnt_level(:,l) + bench_tot.R_cnt_level(:,l);
         end
         for l = 1:n_levels_b
            R_cnt_level(:,l) = R_cnt_level(:,l) + b.R_cnt_level(:,l);
         end
         bench_tot.R_cnt_level = R_cnt_level;
         % update counts for precision computation
         bench_tot.P_num_bdry = bench_tot.P_num_bdry + b.P_num_bdry;
         bench_tot.P_cnt_bdry = bench_tot.P_cnt_bdry + b.P_cnt_bdry;
         % update per-level histograms
         n_lvl_bins = numel(bench_tot.level_bin_cntrs);
         level_ucm_hist = zeros([n_lvl_bins n_levels]);
         for l = 1:n_levels_tot
            level_ucm_hist(:,l) = ...
               level_ucm_hist(:,l) + bench_tot.level_ucm_hist(:,l);
         end
         for l = 1:n_levels_b
            level_ucm_hist(:,l) = ...
               level_ucm_hist(:,l) + b.level_ucm_hist(:,l);
         end
         bench_tot.level_ucm_hist = level_ucm_hist;
      end
   end
   % compute overall precision-recall curves
   bench_tot.R = ...
      bench_tot.R_cnt_bdry ./ ...
         (bench_tot.gt_num_bdry + (bench_tot.gt_num_bdry==0));
   bench_tot.P = ...
      bench_tot.P_cnt_bdry ./ ...
         (bench_tot.P_num_bdry + (bench_tot.P_num_bdry==0));
   % compute overall f-measure as function of threshold
   bench_tot.F = fmeasure(bench_tot.R, bench_tot.P);
   % find optimal threshold
   [bestT bestR bestP bestF] = ...
      maxF(bench_tot.thresh, bench_tot.R, bench_tot.P);
   % store optimal point on precision-recall curve
   bench_tot.bestT = bestT;
   bench_tot.bestR = bestR;
   bench_tot.bestP = bestP;
   bench_tot.bestF = bestF;
end

% compute f-measure fromm recall and precision
function [f] = fmeasure(r, p)
   f = 2*p.*r./(p+r+((p+r)==0));
end

% interpolate to find best F and coordinates thereof
function [bestT bestR bestP bestF] = maxF(thresh, R, P)
   bestT = thresh(1);
   bestR = R(1);
   bestP = P(1);
   bestF = fmeasure(R(1),P(1));
   for i = 2:numel(thresh),
      for d = linspace(0,1),
         t = thresh(i)*d + thresh(i-1)*(1-d);
         r = R(i)*d + R(i-1)*(1-d);
         p = P(i)*d + P(i-1)*(1-d);
         f = fmeasure(r,p);
         if f > bestF,
            bestT = t;
            bestR = r;
            bestP = p;
            bestF = f;
         end
      end
   end
end
