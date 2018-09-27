function offsets = generate_neighbor_offsets( a )

sz = size( a );
N = length( sz );
[ neighbor_subs{ 1 : N } ] = ndgrid( 1 : 3 );
center_sub( 1 : N ) = { 2 };
neighbor_indices = sub2ind( sz, neighbor_subs{ : } );
center_index = sub2ind( sz, center_sub{ : } );
offsets = neighbor_indices - center_index;
offsets = offsets( : );
offsets( offsets == 0 ) = [];

end

