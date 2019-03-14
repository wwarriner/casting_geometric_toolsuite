function [ quantiles, uv, uw ] = div_to_quant( ...
    divisions, ...
    values, ...
    weights, ...
    interp_method ...
    )

if nargin < 3
    weights = qd_uniform_weights( values );
end
if nargin < 4
    interp_method = 'linear';
end

[ uv, uw ] = qd_unique( values, weights );
quantiles = qd_interp( divisions, uv, uw, interp_method );

end

