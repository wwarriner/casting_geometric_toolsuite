s = StlFile( which( "bearing_block.stl" ) );
b = Body( s.fv );

[ node, elem, external_faces ] = s2m( b.fv.vertices, b.fv.faces, 0.5, b.volume ./ 100 );
plotmesh( node, elem, external_faces );
external_faces = external_faces( :, 1 : 3 );
[ external_faces, ex_sort_inds ] = sort( external_faces, 2, "ascend" );
rev_ex_sort_inds = repmat( 1 : size( ex_sort_inds, 2 ), size( ex_sort_inds, 1 ), 1 );
newInd( ex_sort_inds ) = rev_ex_sort_inds; % TODO fix reverse sorting
external_areas = compute_triangle_areas( external_faces, node );

a = node( elem( :, 1 ), : );
b = node( elem( :, 2 ), : );
c = node( elem( :, 3 ), : );
d = node( elem( :, 4 ), : );
volumes = abs( dot( a-d, cross( b-d, c-d, 2 ), 2 ) ) / 6.0;

f1 = elem( :, [ 1 2 3 ] );
f2 = elem( :, [ 1 2 4 ] );
f3 = elem( :, [ 1 3 4 ] );
f4 = elem( :, [ 2 3 4 ] );
all_faces = [ f1; f2; f3; f4 ];
[ all_faces, sort_inds ] = sort( all_faces, 2, "ascend" );
[ all_faces, unique_inds ] = unique( all_faces, "rows" );
internal_faces = setdiff( all_faces, external_faces, "rows" );
internal_areas = compute_triangle_areas( internal_faces, node );

%external_faces = 
