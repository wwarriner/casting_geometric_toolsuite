function plot_pareto_fronts( results )

objective_start_column = results.Properties.UserData.ObjectiveStartColumn;
column_count = size( results, 2 );
objective_count = column_count - objective_start_column + 1;
fh = figure();
for i = objective_start_column : column_count

    for j = i + 1 : column_count
    
        subplot_position = ...
            ( i - objective_start_column ) * objective_count ...
            + ( j - objective_start_column ) + 1;
        axh = subplot( objective_count, objective_count, subplot_position );
        hold( axh, 'on' );
        vj = rescale( results{ :, j } );
        vi = rescale( results{ :, i } );
        plot( vj, vi, 'k*' );
        plot( vj( results.is_pareto_dominant ), vi( results.is_pareto_dominant ), 'r*' );
        axis( axh, 'square' );
        
    end
    
end