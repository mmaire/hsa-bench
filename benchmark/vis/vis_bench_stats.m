% Visualize benchmark statistics and (optionally) write to output files.
%
% vis_bench_stats(bench, outdir)
%
% Input:
%    bench     - benchmark data
%    max_level - maximum hiearchy level to plot (default: all)
%    outdir    - (optional) output directory to write results
%                (skip if [] or not specified; default: skip output)
%    bg_color  - figure background color (default: white)
function vis_bench(bench, max_level, outdir, bg_color)
   % default arguments
   if (nargin < 2), max_level = []; end
   if (nargin < 3), outdir = []; end
   if (nargin < 4), bg_color = 'w'; end
   % visualization parameters
   params.thicken_width = 2;  % amount to thicken boundaries for visualization
   params.isoF_line_width  = 1;
   params.plot_line_width  = 2;
   params.plot_marker_size = 25;
   params.font_size = 15;
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
   xlabel('Recall','FontSize',params.font_size);
   ylabel('Precision','FontSize',params.font_size);
   title([ ...
      'Boundary Detection [F=' num2str(bench.bestF, '%2.2f') ...
      ' (R=' num2str(bench.bestR, '%2.2f') ...
      ',P=' num2str(bench.bestP, '%2.2f') ')]' ...
   ],'FontSize',params.font_size);
   whitebg(fh,bg_color);
   set(fh,'color',bg_color);
   set(fh,'inverthardcopy','off');
   % compute boundary level recovery fraction as function of threshold
   n_thresh = numel(bench.thresh);
   n_levels = numel(bench.gt_num_level);
   % cap number of levels to show if specified
   if (~isempty(max_level))
      n_levels = min(n_levels, max_level);
   end
   level_frac = zeros([n_thresh n_levels]);
   for l = 1:n_levels
      level_frac(:,l) = bench.R_cnt_level(:,l) ./ bench.gt_num_level(l);
   end
   % display boundary recovery by overall recall
   fh = figure(3);
   legend_labels = cell([1 n_levels]);
   colors = {'r', 'b', 'g', 'm', 'c', 'k', 'y'};
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
   xlabel('Overall Boundary Recall','FontSize',params.font_size);
   ylabel('Level Recovery Fraction','FontSize',params.font_size);
   title('Boundary Recovery Order by Hierarchy Level', ...
      'FontSize',params.font_size);
   legend(legend_labels, 'Location', 'SouthEast', 'FontSize',params.font_size);
   whitebg(fh,bg_color);
   set(fh,'color',bg_color);
   set(fh,'inverthardcopy','off');
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
   xlabel('Predicted Boundary Strength','FontSize',params.font_size);
   ylabel('Fraction of Assigned Pixels','FontSize',params.font_size);
   title('Boundary Strength Distribution by Level in Hierarchy', ...
      'FontSize',params.font_size);
   legend(legend_labels, 'Location', 'NorthWest', 'FontSize',params.font_size);
   whitebg(fh,bg_color);
   set(fh,'color',bg_color);
   set(fh,'inverthardcopy','off');
   % check whether to create output files
   if (~isempty(outdir))
      % get working directory
      wd = cd;
      % switch to output directory
      cd(outdir);
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
