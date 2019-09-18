% ========================================================
% ========= set scaling as necessary =========
% ========================================================
function [ yhat, yscale, yshift ] = scaleproblem( y )
% chooses an appropriate scaling for the problem
% there is no need to scale x, since each knot interval is already
% implicitly normalized into [0,1]. x is passed in only for
% a few parameters, such as the integral constraint, where x would
% be needed.

% scale y so that the minimum value is 1/phi, and the maximum value phi.
% where phi is the golden ratio, so phi = (sqrt(5) + 1)/2 = 1.6180...
% Note that phi - 1/phi = 1, so the new range of yhat is 1. (Note that
% this interval was carefully chosen to bring y as close to 1 as
% possible, with an interval length of 1.)
%
% The transformation is:
%   yhat = y*yscale + yshift
phi_inverse = (sqrt(5) - 1)/2;

% shift and scale are determined from the min and max of y.
ymin = min(y);
ymax = max(y);

yscale = 1 ./ (ymax - ymin);
if isinf( yscale )
    % in case data was passed in that is constant, then
    % the range of y is zero. No scaling need be done then.
    yscale = 1;
end

% recover the shift once the scale factor is known.
yshift = phi_inverse - yscale*ymin;

% scale y to refect the shift and scale
yhat = y*yscale + yshift;

end

