function plot_csv_data( results_table, quantiles )

ANGLE_COLUMNS = [ 1 2 ];
angles = results_table{ :, ANGLE_COLUMNS };
OBJECTIVE_START_COLUMN = max( ANGLE_COLUMNS ) + 1;
objectives = results_table{ :, OBJECTIVE_START_COLUMN : end };

[ interp_methods, titles ] = multiple_objective_opt();
count = numel( titles );
interpolants = cell( count, 1 );
for i = 1 : count
    
    interpolants{ i } = generate_unit_sphere_scattered_interpolant( ...
        angles, ...
        objectives( :, i ), ...
        interp_methods{ i } ...
        );
    plot_unit_sphere_response_surface( ...
        interpolants{ i }, ...
        [ 600 600 ], ...
        titles{ i }, ...
        plasma(), ...
        '2d' ...
        );
    divisions = determine_unit_sphere_function_quantile_values( ...
        interpolants{ i }, ...
        quantiles, ...
        interp_methods{ i } ...
        );
    plot_unit_sphere_response_surface( ...
        quantile_plot( interpolants{ i }, divisions ), ...
        [ 600 600 ], ...
        [ titles{ i } '_quantiles' ], ...
        special_cmap(), ...
        '2d' ...
        );
    
end

end


function quantile_plot_fn = quantile_plot( interpolant, divisions, quantiles )

if nargin < 3
    quantiles = 1 : ( length( divisions ) + 1 );
end

    function label = qplot( x, y )
        
        divisions = [ divisions 1e300 ];
        [ ~, ia ] = unique( divisions );
        quantiles = [ quantiles 1 ];
        label = interp1( divisions( ia ), quantiles( ia ), interpolant( x, y ), 'next', 'extrap' );
        
    end
quantile_plot_fn = @qplot;

end


function cmap = special_cmap( intensity_range )

cmap = plasma( 512 );
cmap = cmap( 1 : 384, : );

end
