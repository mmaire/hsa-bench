% Load machine-generated ucm and apply morphological thinning.
%
% [ucm] = load_ucm(fname)
%
% Input:
%    fname  - name of image file containing ucm to load
%
% Output:
%    ucm    - thinned ucm with values in range [0, 1]
function [ucm] = load_ucm(fname)
   % read image file and map to [0, 1] range
   ucm = double(imread(fname))./255;
   % thin ucm boundaries
   ucm_t = bwmorph(double(ucm > 0), 'thin', inf);
   % mask ucm values by thinned boundaries
   ucm = ucm_t.*ucm;
end
