% Generate a groundtruth ucm from a mapping of pixels to groundtruth levels.
%
% [gt_ucm] = generate_gt_ucm(levels)
%
% Note: The mapping from level to boundary strength is arbitrary except for
% the requirement that a lower level maps to a higher strength.  We choose to
% equally space levels in the range [0, 1] for this visualization.
%
% Input:
%    levels - level of each boundary pixel in hierarchy
%
% Output:
%    gt_ucm - example groundtruth ucm (for visualization purposes only)
function [gt_ucm] = generate_gt_ucm(levels)
   % allocate groundtruth ucm matrix
   gt_ucm = zeros(size(levels));
   % get boundary pixels
   inds = find(levels);
   vals = levels(inds);
   % get maximum level value
   m = max(vals);
   % map level to strength
   gt_ucm(inds) = ((m+1) - vals)./m;
end
