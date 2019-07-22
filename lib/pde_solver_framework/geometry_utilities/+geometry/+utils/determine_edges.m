function edges = determine_edges( fv )

count = size( fv.faces, 1 );
edges = zeros( 3 * count, 2 );
edges( 1 : count, : ) = fv.faces( :, [ 1 2 ] );
edges( count + 1 : 2 * count, : ) = fv.faces( :, [ 2 3 ] );
edges( 2 * count + 1 : end, : ) = fv.faces( :, [ 3 1 ] );
edges = sort( edges.' ).';
edges = unique( edges, 'rows' );

end

