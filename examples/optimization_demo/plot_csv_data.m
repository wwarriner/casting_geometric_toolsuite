function plot_csv_data( results_table )

ANGLE_COLUMNS = [ 1 2 ];
angles = results_table{ :, ANGLE_COLUMNS };
OBJECTIVE_START_COLUMN = max( ANGLE_COLUMNS ) + 1;
objectives = results_table{ :, OBJECTIVE_START_COLUMN : end };

[ interp_methods, titles ] = multiple_objective_opt();
count = numel( titles );
interpolants = cell( count, 1 );
for i = 1 : count
    
    interpolants{ i } = generate_scattered_spherical_interpolant( ...
        angles, ...
        objectives( :, i ), ...
        interp_methods{ i } ...
        );
    plot_response_surface( ...
        interpolants{ i }, ...
        [ 600 600 ], ...
        titles{ i }, ...
        '2d' ...
        );
    quantiles = [ 0.01 0.05 0.25 0.5 0.75 0.95 0.99 ];
    divs = quantile_on_sphere_surface( interpolants{ i }, quantiles, interp_methods{ i } );
    plot_response_surface( ...
        quantile_plot( interpolants{ i }, divs ), ...
        [ 600 600 ], ...
        [ titles{ i } '_quantiles' ], ...
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