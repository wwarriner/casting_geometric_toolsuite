function interpolant = generate_unit_sphere_quantile_interpolant( ...
    gridded_thetas, ...
    gridded_phi_theta_values, ...
    interp_method ...
    )
%% DETERMINE WEIGHTS
weights = abs( sin( gridded_thetas ) );

%% CREATE Q-Q-LIKE PLOT
samples = sortrows( [ gridded_phi_theta_values( : ) weights( : ) ], 1 );
values = samples( :, 1 );
weights = samples( :, 2 );
normalized_cumulative_weight = cumsum( weights ) ./ sum( weights );
[ unique_values, unique_indices ] = unique( values );
unique_weights = normalized_cumulative_weight( unique_indices );
[ unique_weights, unique_indices ] = unique( unique_weights );
unique_values = unique_values( unique_indices );

%% GENERATE INTERPOLANT
if strcmpi( interp_method, 'nearest' )
    interp_method = 'next';
end
    function division = interp( quantile )
        
        division = interp1( unique_weights, unique_values, quantile, interp_method );
        if isnan( division )
            division = max( unique_values );
        end
        
    end
interpolant = @interp;

end

