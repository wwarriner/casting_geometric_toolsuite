function [ divisions, uv, uw ] = quant_to_div( ...
    quantiles, ...
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
divisions = qd_interp( quantiles, uw, uv, interp_method );

end

