function [ phs, quantiles ] = plot_divisions( varargin )

if isa( varargin{ 1 }, 'matlab.graphics.axis.Axes' )
    axh = varargin{ 1 };
    varargin = varargin( 2 : end );
else
    figure();
    axh = axes();
end
divisions = varargin{ 1 };
values = varargin{ 2 };
if numel( varargin ) < 3
    weights = qd_uniform_weights( values );
else
    weights = varargin{ 3 };
end
if numel( varargin ) < 4
    interp_method = 'linear';
else
    interp_method = varargin{ 4 };
end

[ quantiles, uv, uw ] = ...
    div_to_quant( divisions, values, weights, interp_method );
phs = qd_plot( axh, divisions, quantiles, uv, uw );

end

