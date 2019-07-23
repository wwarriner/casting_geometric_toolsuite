function distances = find_loop_distances( loop )
% loop is a logical matrix containing a single closed 8-connected loop.
% use clean_perimeter prior to this

assert( bweuler( loop ) == 0 );
assert( any( loop, 'all' ) );



indices = zeros( 1, sum( perimeter( : ) ) + 1 );
distances = zeros( 1, sum( perimeter( : ) ) );

INVALID_ELEMENT = 0;
VALID_ELEMENT = 1;
offsets = generate_neighbor_offsets( perimeter );
preferred_neighbors = [ 7 8 5 3 2 1 4 6 ];
neighbor_distances = [ sqrt( 2 ) 1 sqrt( 2 ) 1 1 sqrt( 2 ) 1 sqrt( 2 ) ];

itr = 1;
indices( itr ) = find( perimeter, 1 );

itr = itr + 1;
while true
    % get next index
    neighbors = indices( itr - 1 ) + offsets;
    valid_neighbors = perimeter( neighbors ) == VALID_ELEMENT;
    first_available_preference = find( valid_neighbors( preferred_neighbors ), 1 );
    % end condition
    if isempty( first_available_preference )
        % either loop is complete, or isn't a closed loop
        % because we are marking elements invalid as we pass
        break;
    end
    % updates
    next_index = neighbors( preferred_neighbors( first_available_preference ) );
    indices( itr ) = next_index;
    distances( itr - 1 ) = neighbor_distances( preferred_neighbors( first_available_preference ) );
    perimeter( next_index ) = INVALID_ELEMENT;
    itr = itr + 1;
end
% Prepare Output
assert( indices( 1 ) == indices( end ) );
indices = indices( 1 : end - 1 );

end

