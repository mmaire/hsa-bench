% Thicken a (machine-generated or groundtruth) ucm for visualization purposes.
%
% [ucm_thick] = thicken_ucm(ucm, width)
%
% Input:
%    ucm       - ultrametric contour map with values in range [0,1]
%    width     - width of thickening kernel (default: 1 pixel)
%
% Output:
%    ucm_thick - ucm with thickened boundaries (by width pixels)
function [ucm_thick] = thicken_ucm(ucm, width)
   % default arguments
   if (nargin < 2), width = 1; end
   % initialize thickened ucm
   ucm_thick = ucm;
   % repeatedly thicken
   for n = 1:width
      ucm_curr = ucm_thick;
      ucm_thick = max(ucm_thick, shift_ucm(ucm_curr,  0,  1));
      ucm_thick = max(ucm_thick, shift_ucm(ucm_curr,  0, -1));
      ucm_thick = max(ucm_thick, shift_ucm(ucm_curr,  1,  0));
      ucm_thick = max(ucm_thick, shift_ucm(ucm_curr, -1,  0));
      ucm_thick = max(ucm_thick, shift_ucm(ucm_curr,  1,  1));
      ucm_thick = max(ucm_thick, shift_ucm(ucm_curr, -1,  1));
      ucm_thick = max(ucm_thick, shift_ucm(ucm_curr,  1, -1));
      ucm_thick = max(ucm_thick, shift_ucm(ucm_curr, -1, -1));
   end
end

% Shift 2D ucm matrix in specified direction.
%
% [ucm_shift] = shift_ucm(ucm, offset_x, offset_y)
%
% Input:
%    ucm       - ultrametric contour map with values in range [0,1]
%    offset_x  - x-direction offset (-1, 0, or 1)
%    offset_y  - y-direction offset (-1, 0, or 1)
%
% Ouput:
%    ucm_shift - ucm shifted specified direction
function [ucm_shift] = shift_ucm(ucm, offset_x, offset_y)
   % get image size
   sx = size(ucm,1);
   sy = size(ucm,2);
   % initialize shifted ucm
   ucm_shift = ucm;
   % shift by x-offset
   if (offset_x == 1)
      ucm_shift = [ucm_shift(2:end,:); zeros([1 sy])];
   elseif (offset_x == -1)
      ucm_shift = [zeros([1 sy]); ucm_shift(1:end-1,:)];
   end
   % shift by y-offset
   if (offset_y == 1)
      ucm_shift = [ucm_shift(:,2:end) zeros([sx 1])];
   elseif (offset_y == -1)
      ucm_shift = [zeros([sx 1]) ucm_shift(:,1:end-1)];
   end
end
