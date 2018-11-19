function divisions = quantile_on_sphere_surface( func_phi_theta, quantiles, interp_method, resolution )
%% INPUTS
if nargin < 4
    resolution = 200;
end

%% DETERMINE WEIGHTS AND VALUES FROM FUNCTION
[ phis, thetas ] = unit_sph_grid_values( resolution );
[ phis, thetas ] = meshgrid( phis, thetas );
weights = abs( sin( thetas ) );
values = func_phi_theta( phis, thetas );

%% CREATE Q-Q-LIKE PLOT
samples = sortrows( [ values( : ) weights( : ) ], 1 );
values = samples( :, 1 );
weights = samples( :, 2 );
normalized_cumulative_weight = cumsum( weights ) ./ sum( weights );
[ unique_values, unique_indices ] = unique( values );
unique_weights = normalized_cumulative_weight( unique_indices );
[ unique_weights, unique_indices ] = unique( unique_weights );
unique_values = unique_values( unique_indices );

%% DETERMINE DIVISIONS
if strcmpi( interp_method, 'nearest' )
    interp_method = 'next';
end
divisions = interp1( unique_weights, unique_values, quantiles, interp_method );
if isnan( divisions( end ) )
    divisions( end ) = max( unique_values );
end

%% PLOT Q-Q
fh = figure( 'color', 'w', 'name', 'Q-Q Plot' );
axh = axes( fh );
hold on;
if length( unique_values ) > 100
    linespec = 'k';
else
    linespec = 'k.';
end
value_scaler = create_value_scaler( unique_values );
scaled_values = value_scaler( unique_values );
plot( axh, unique_weights, scaled_values, linespec ); axis( 'square' ); xlim( [ 0 1 ] );
plot( axh, [ 0 1 ], [ 0 1 ], 'k:' );
qq_divisions = value_scaler( divisions );
for i = 1 : length( divisions )
    
    plot( axh, quantiles, qq_divisions, 'r+' );
    
end

end


function value_scaler = create_value_scaler( values )

    function vq = vs( xq )
        
        vq = interp1( ...
            [ min( values( : ) ) max( values( : ) ) ], ...
            [ 0 1 ], ...
            xq ...
            );
        
    end
value_scaler = @vs;

end

