% Evaluate quality of machine-generated hierarchical boundaries as compared to
% those derived from a groundtruth region tree.
%
% [bench] = eval_boundary(im, rtree, ucm)
%
% Input:
%    im                 - original image
%    rtree              - groundtruth region tree annotation
%    ucm                - thinned ucm to evaluate with values in range [0, 1]
%
% Output:
%    bench.             - benchmark data
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
%       match_ucm       - matches at optimal threshold (ucm -> groundtruth)
%       match_gt        - matches at optimal threshold (groundtruth -> ucm)
%
%       level_ucm_vals  - for each groundtruth level, list of strengths of
%                         matched pixels in the machine-generated ucm
%                         (with matching done at the optimal threshold)
%       level_ucm_hist  - same as above, but in the form of histogram counts
%                         for equally spaced ucm value bins at each level
%       level_bin_cntrs - bin centers for above histogram
function [bench] = eval_boundary(im, rtree, ucm)
   % parameter settings
   params.max_dist = 0.0075; % max match distance as fraction of image diagonal
   params.n_thresh = 99;     % number of thresholds in precision-recall curves
   params.n_lvl_bins = 100;  % number of bins in per-level ucm value histograms
   % generate thresholds
   thresh = ...
      linspace(1/(params.n_thresh+1),1-1/(params.n_thresh+1),params.n_thresh)';
   % generate level histogram bin centers
   lvl_bin_step = 1./(params.n_lvl_bins);
   lvl_bin_centers = (lvl_bin_step./2):lvl_bin_step:1;
   % extract groundtruth boundary information
   [bmap fg_map levels] = render_bmap(im, rtree);
   % compute map of object-part boundaries
   op_map = bmap - fg_map;
   % get number of groundtruth boundary levels
   n_levels = max(levels(:));
   % initialize counts of number of groundtruth boundary pixels
   bench.gt_num_bdry    = sum(bmap(:));
   bench.gt_num_bdry_fg = sum(fg_map(:));
   bench.gt_num_bdry_op = sum(op_map(:));
   bench.gt_num_level   = zeros([1 n_levels]);
   % count number of groundtruth boundary pixels at each level
   level_labels_sorted = sort(levels(:));
   [level_nums pos_start] = unique(level_labels_sorted, 'first');
   [level_nums pos_end]   = unique(level_labels_sorted, 'last');
   for l = 1:numel(level_nums)
      if (level_nums(l) > 0)
         bench.gt_num_level(level_nums(l)) = pos_end(l) - pos_start(l) + 1;
      end
   end
   % store thresholds
   bench.thresh = thresh;
   % initialize recall and precision counts
   bench.R_cnt_bdry    = zeros([params.n_thresh 1]);
   bench.R_cnt_bdry_fg = zeros([params.n_thresh 1]);
   bench.R_cnt_bdry_op = zeros([params.n_thresh 1]);
   bench.R_cnt_level   = zeros([params.n_thresh n_levels]);
   bench.P_num_bdry    = zeros([params.n_thresh 1]);
   bench.P_cnt_bdry    = zeros([params.n_thresh 1]);
   % compute boundary correspondence at each threshold
   for t = 1:params.n_thresh
      % threshold machine-generated ucm
      th = thresh(t);
      ucm_th = double(ucm >= th);
      % match with groundtruth boundary map
      [match_ucm match_gt] = correspondPixels(ucm_th, bmap, params.max_dist);
      % restrict groundtruth match set by boundary type
      match_gt_fg = match_gt.*fg_map;
      match_gt_op = match_gt.*op_map;
      match_gt_level = cell([1 n_levels]);
      for l = 1:n_levels
         match_gt_level{l} = match_gt.*(levels == l);
      end
      % update counts of recalled pixels
      bench.R_cnt_bdry(t)    = sum(match_gt(:)    > 0);
      bench.R_cnt_bdry_fg(t) = sum(match_gt_fg(:) > 0);
      bench.R_cnt_bdry_op(t) = sum(match_gt_op(:) > 0);
      for l = 1:n_levels
         m_gt_lvl = match_gt_level{l};
         bench.R_cnt_level(t, l) = sum(m_gt_lvl(:) > 0);
      end
      % update counts for precision computation
      bench.P_num_bdry(t) = sum(ucm_th(:));
      bench.P_cnt_bdry(t) = sum(match_ucm(:) > 0);
   end
   % compute overall precision-recall curves
   bench.R = bench.R_cnt_bdry ./ (bench.gt_num_bdry + (bench.gt_num_bdry==0));
   bench.P = bench.P_cnt_bdry ./ (bench.P_num_bdry + (bench.P_num_bdry==0));
   % compute overall f-measure as function of threshold
   bench.F = fmeasure(bench.R, bench.P);
   % find optimal threshold
   [bestT bestR bestP bestF] = maxF(thresh, bench.R, bench.P);
   % store optimal point on precision-recall curve
   bench.bestT = bestT;
   bench.bestR = bestR;
   bench.bestP = bestP;
   bench.bestF = bestF;
   % recompute matches at optimal threshold
   ucm_th = double(ucm >= bestT);
   [match_ucm match_gt] = correspondPixels(ucm_th, bmap, params.max_dist);
   % store matches at optimal threshold
   bench.match_ucm = match_ucm;
   bench.match_gt  = match_gt;
   % restrict groundtruth match set by boundary level
   match_gt_level = cell([1 n_levels]);
   for l = 1:n_levels
      match_gt_level{l} = match_gt.*(levels == l);
   end
   % partition by level the groundtruth pixels matched at optimal threshold
   bench.level_ucm_vals = cell([1 n_levels]);
   bench.level_ucm_hist = zeros([params.n_lvl_bins n_levels]);
   for l = 1:n_levels
      % lookup ucm values for groundtruth pixels of level
      m_gt_lvl = match_gt_level{l};
      inds_gt  = find(m_gt_lvl > 0);
      inds_ucm = m_gt_lvl(inds_gt);
      vals_ucm = ucm(inds_ucm);
      % store ucm values
      bench.level_ucm_vals{l} = vals_ucm;
      % histogram ucm values
      bench.level_ucm_hist(:,l) = hist(vals_ucm, lvl_bin_centers);
   end
   % store bin centers
   bench.level_bin_cntrs = lvl_bin_centers;
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
