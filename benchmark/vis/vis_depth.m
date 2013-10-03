% Visualize groundtruth depth maps and (optionally) write to output files.
%
% vis_depth(im, rtree, outdir)
%
% Input:
%    im        - original image
%    rtree     - groundtruth region tree annotation
%    outdir    - (optional) output directory to write results
%                (skip if [] or not specified; default: skip output)
function vis_depth(im, rtree, outdir)
   % default arguments
   if (nargin < 3), outdir = []; end
   % render groundtruth depth
   [seg_ids seg_levels seg_depth] = render_seg(im, rtree);
   im_depth = ind2rgb(round(seg_depth.*255)+1, jet(256));
   % display visualization
   figure(1); imagesc(im); axis image;
   figure(2); imagesc(im_depth); axis image;
   drawnow;
   % write output
   if (~isempty(outdir))
      % get working directory
      wd = cd;
      % switch to output directory
      cd(outdir);
      % write depth visualization
      imwrite(im_depth, 'depth.png');
      % restore working directory
      cd(wd);
   end
end
