function subs = generate_neighbor_subs( a )

N = ndims( a );
[ subs{ 1 : N } ] = ndgrid( 1 : 3 );
subs = cell2mat( subs );
subs = reshape( subs, [], 2 ) - 2;
center_sub( 1 : N ) = { 2 };
center_index = sub2ind( 3 * ones( N, 1 ), center_sub{ : } );
subs( center_index, : ) = [];

end

