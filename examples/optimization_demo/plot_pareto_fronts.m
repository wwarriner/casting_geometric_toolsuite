function plot_pareto_fronts( results )

objective_count = size( results, 2 ) - 2;
values = results{ :, 3 : end };
pareto_indices = find_pareto_indices( values );
fh = figure();
for i = 1 : objective_count

    for j = i + 1 : objective_count
    
        axh = subplot( objective_count, objective_count, i * objective_count + j );
        hold( axh, 'on' );
        vj = rescale( values( :, j ) );
        vi = rescale( values( :, i ) );
        plot( vj, vi, 'k*' );
        plot( vj( pareto_indices ), vi( pareto_indices ), 'r*' );
        axis( axh, 'square' );
        
    end
    
end