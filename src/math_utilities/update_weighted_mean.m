function m = update_weighted_mean( v, new_w, m, old_w )

if nargin < 3
    m = 0;
    old_w = 0;
end

W = old_w + sum( new_w );
m = ( m * old_w + sum( v .* new_w ) ) ./ W;

end

