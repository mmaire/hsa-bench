% Visualize benchmark results and (optionally) write to output files.
%
% vis_bench(im, rtree, ucm, bench, outdir)
%
% Input:
%    im        - original image
%    rtree     - groundtruth region tree annotation
%    ucm       - thinned ucm with values in range [0, 1]
%    bench     - benchmark data
%    outdir    - (optional) output directory to write results
%                (skip if [] or not specified; default: skip output)
function vis_bench(im, rtree, ucm, bench, outdir)
   % default arguments
   if (nargin < 5), outdir = []; end
   % visualization parameters
   params.thicken_width = 2;  % amount to thicken boundaries for visualization
   params.isoF_line_width  = 1;
   params.plot_line_width  = 5;
   params.plot_marker_size = 35;
   % render groundtruth boundaries
   [bmap fg_map levels] = render_bmap(im, rtree);
   % compute groundtruth ucm
   ucm_gt = generate_gt_ucm(levels);
   % compute ucm at optimal threshold
   ucm_th = ucm.*(ucm >= bench.bestT);
   % generate ucm visualization
   vis_ucm_gt = thicken_ucm(ucm_gt, params.thicken_width);
   vis_ucm    = thicken_ucm(ucm, params.thicken_width);
   vis_ucm_th = thicken_ucm(ucm_th, params.thicken_width);
   im_ucm_gt  = repmat(1 - vis_ucm_gt, [1 1 3]);
   im_ucm     = repmat(1 - vis_ucm, [1 1 3]);
   im_ucm_th  = repmat(1 - vis_ucm_th, [1 1 3]);
   % transfer machine ucm weights to groundtruth ucm at optimal threshold
   ucm_gt_rw = zeros(size(ucm_gt));
   inds_ucm_gt = find(bench.match_gt > 0);
   inds_ucm    = bench.match_gt(inds_ucm_gt);
   vals_ucm    = ucm(inds_ucm);
   ucm_gt_rw(inds_ucm_gt) = vals_ucm;
   % transfer groundtruth ucm weights to machine ucm at optimal threshold
   ucm_rw = zeros(size(ucm));
   inds_ucm    = find(bench.match_ucm > 0);
   inds_ucm_gt = bench.match_ucm(inds_ucm);
   vals_ucm_gt = ucm_gt(inds_ucm_gt);
   ucm_rw(inds_ucm) = vals_ucm_gt;
   % generate reweighted visualizations
   vis_ucm_gt_rw = thicken_ucm(ucm_gt_rw, params.thicken_width);
   vis_ucm_rw    = thicken_ucm(ucm_rw, params.thicken_width);
   im_ucm_gt_rw  = repmat(1 - vis_ucm_gt_rw, [1 1 3]);
   im_ucm_rw     = repmat(1 - vis_ucm_rw, [1 1 3]);
   % generate residual visualization
   vis_ucm_gt_res = abs(vis_ucm_gt_rw - vis_ucm_gt);
   vis_ucm_res    = abs(vis_ucm_rw - vis_ucm_th);
   im_ucm_gt_res  = repmat(1 - vis_ucm_gt_res, [1 1 3]);
   im_ucm_res     = repmat(1 - vis_ucm_res, [1 1 3]);
   % generate combined residual visualization
   sx = size(im,1);
   sy = size(im,2);
   im_comb_ucm_gt_res = ones([sx sy 3]);
   im_comb_ucm_res    = ones([sx sy 3]);
   im_comb_ucm_gt_res(:,:,1) = 1 - vis_ucm_gt_res;
   im_comb_ucm_gt_res(:,:,3) = 1 - vis_ucm_gt_res;
   im_comb_ucm_res(:,:,2)    = 1 - vis_ucm_res;
   im_comb_ucm_res(:,:,3)    = 1 - vis_ucm_res;
   im_comb_res = min(im_comb_ucm_gt_res, im_comb_ucm_res);
   % display match visualization
   figure(1);
   subplot(1,4,1); imagesc(im);
   axis('image','off'); colormap('gray'); title('Image');
   subplot(1,4,2); imagesc(im_ucm_gt);
   axis('image','off'); colormap('gray'); title('Groundtruth UCM');
   subplot(1,4,3); imagesc(im_ucm);
   axis('image','off'); colormap('gray'); title('gPb-UCM');
   subplot(1,4,4); imagesc(im_comb_res);
   axis('image','off'); colormap('gray');
   title(['Residual at F=' num2str(bench.bestF, '%2.2f')]);
   % display overall precision-recall curve
   fh = figure(2);
   hold('off');
   % plot iso-F lines
   f_vals  = 0.1:0.1:0.9;
   f_color = [0 255 0]./255;
   for f_val = f_vals
      r = f_val:0.01:1;
      p = f_val.*r./(2.*r-f_val);
      figure(fh);
      plot(r, p, 'Color', f_color, 'LineWidth', params.isoF_line_width);
      hold('on');
      figure(fh);
      plot(p, r, 'Color', f_color, 'LineWidth', params.isoF_line_width);
      figure(fh); text(1.01, p(end), num2str(f_val,'%0.1f'), 'Color', f_color);
   end
   text(1.01, 0.975, 'iso-F', 'Color', f_color);
   % plot PR-curve
   figure(fh);
   plot(bench.R, bench.P, 'k', 'LineWidth', params.plot_line_width);
   plot(bench.bestR, bench.bestP, 'm.', 'MarkerSize', params.plot_marker_size);
   hold('off');
   axis('equal'); axis([0 1 0 1]);
   xlabel('Recall'); ylabel('Precision');
   title([ ...
      'Overall Boundary Detection Performance [F=' num2str(bench.bestF, '%2.2f') ...
      ' (R=' num2str(bench.bestR, '%2.2f') ...
      ', P=' num2str(bench.bestP, '%2.2f') ')]' ...
   ]);
   whitebg(fh,'w');
   % compute boundary level recovery fraction as function of threshold
   n_thresh = numel(bench.thresh);
   n_levels = numel(bench.gt_num_level);
   level_frac = zeros([n_thresh n_levels]);
   for l = 1:n_levels
      level_frac(:,l) = bench.R_cnt_level(:,l) ./ bench.gt_num_level(l);
   end
   % display boundary recovery by overall recall
   fh = figure(3);
   legend_labels = cell([1 n_levels]);
   colors = {'r-.', 'b:', 'g--', 'm', 'c', 'k', 'y'}; 
   for l = 1:n_levels
      figure(fh);
      plot( ...
         bench.R, level_frac(:,l), colors{l}, ...
         'LineWidth', params.plot_line_width ...
      );
      hold('on');
      legend_labels{l} = ['Level ' num2str(l)];
   end
   hold('off');
   axis('equal'); axis([0 1 0 1]);
   xlabel('Overall Boundary Recall'); ylabel('Level Recovery Fraction');
   title('Boundary Recovery Order by Level in Hierarchy');
   legend(legend_labels, 'Location', 'SouthEast');
   whitebg(fh,'w');
   % display histograms of boundary strength mapping
   fh = figure(4);
   for l = 1:n_levels;
      figure(fh);
      plot( ...
         bench.level_bin_cntrs, ...
         bench.level_ucm_hist(:,l) ./ (sum(bench.level_ucm_hist(:,l))+eps), ...
         colors{l}, ...
         'LineWidth', params.plot_line_width ...
      );
      hold('on');
   end
   hold('off');
   axis('tight');
   ax_range = axis;
   axis([0 1 ax_range(3:4)]);
   xlabel('Predicted Boundary Strength');
   ylabel('Fraction of Assigned Pixels');
   title('Boundary Strength Distribution by Level in Hierarchy');
   legend(legend_labels, 'Location', 'NorthWest');
   whitebg(fh,'w');
   % check whether to create output files
   if (~isempty(outdir))
      % get working directory
      wd = cd;
      % switch to output directory
      cd(outdir);
      % write boundary visualization
      imwrite(im_ucm_gt,     'ucm_gt.png');
      imwrite(im_ucm,        'ucm.png');
      imwrite(im_ucm_th,     'ucm_th.png');
      imwrite(im_ucm_gt_rw,  'ucm_gt_rw.png');
      imwrite(im_ucm_rw,     'ucm_rw.png');
      imwrite(im_ucm_gt_res, 'ucm_gt_res.png');
      imwrite(im_ucm_res,    'ucm_res.png');
      imwrite(im_comb_res,   'ucm_combined_res.png');
      % write figures to png files
      print(2, '-dpng', 'boundary_pr.png');
      print(3, '-dpng', 'boundary_recovery.png');
      print(4, '-dpng', 'boundary_distribution.png');
      % write figures to postscript files
      print(2, '-depsc2', 'boundary_pr.eps');
      print(3, '-depsc2', 'boundary_recovery.eps');
      print(4, '-depsc2', 'boundary_distribution.eps');
      % covert postscript to pdf
      system('ps2pdf14 boundary_pr.eps boundary_pr.pdf');
      system('ps2pdf14 boundary_recovery.eps boundary_recovery.pdf');
      system('ps2pdf14 boundary_distribution.eps boundary_distribution.pdf');
      % restore working directory
      cd(wd);
   end
end
