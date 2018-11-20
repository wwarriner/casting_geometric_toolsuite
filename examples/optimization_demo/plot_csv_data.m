function plot_csv_data( results_table, quantiles )

if nargin < 2
    quantiles = [];
end

objective_start_column = results_table.Properties.UserData.ObjectiveStartColumn;
angles = results_table{ :, 1 : objective_start_column - 1 };

objective_variables_path = results_table.Properties.UserData.ObjectiveVariablesPath;
if isfile( objective_variables_path )
    objective_variables = read_objective_variables( objective_variables_path );
    objective_count = size( objective_variables, 1 );
else
    warning( ...
        [ 'Unable to find objective variables at %s\n' ...
        'Using default titles and interpolation methods.\n' ], ...
        objective_variables_path ...
        );
    objective_count = size( results_table, 2 ) - objective_start_column + 1;
    objective_variables.title = strcat( 'objective ', string( 1 : objective_count ) );
    [ objective_variables.interpolation_method{ 1 : objective_count } ] = deal( 'natural' );
end

interpolants = cell( objective_count, 1 );
for i = 1 : objective_count
    
    objective_values = results_table{ :, objective_variables.title{ i } };
    interpolants{ i } = generate_unit_sphere_scattered_interpolant( ...
        angles, ...
        objective_values, ...
        objective_variables.interpolation_method{ i } ...
        );
    plot_unit_sphere_response_surface( ...
        interpolants{ i }, ...
        [ 600 600 ], ...
        objective_variables.title{ i }, ...
        plasma(), ...
        '2d' ...
        );
    if ~isempty( quantiles )
        divisions = determine_unit_sphere_function_quantile_values( ...
            interpolants{ i }, ...
            quantiles, ...
            objective_variables.interpolation_method{ i } ...
            );
        plot_unit_sphere_response_surface( ...
            quantile_plot( interpolants{ i }, divisions ), ...
            [ 600 600 ], ...
            [ objective_variables.title{ i } '_quantiles' ], ...
            special_cmap(), ...
            '2d' ...
            );
    end
    
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


function cmap = special_cmap()

cmap = plasma( 512 );
cmap = cmap( 1 : 384, : );

end
