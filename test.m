% input = 'C:\Users\wwarr\Desktop\results\steering_column_mount.stl';
% 
% c = Component();
% c.legacy_run( input );
% m = Mesh();
% m.legacy_run( c, 1e6 );
% pp = PartingPerimeter();
% pp.legacy_run( m, 3 );

p_perim = pp.projected_perimeter;
filled_perim = imfill( p_perim, 'holes' );
bound_perim = bwperim( filled_perim );
first = find( bound_perim, 1 );
[ y, x ] = ind2sub( size( p_perim ), first );

INVALID = 0;
VALID = 1;

im = bound_perim;
offsets = generate_neighbor_offsets( bound_perim );
next_index = first;
loop = zeros( 1, sum( im( : ) ) );
right_side_distances = zeros( 1, sum( im( : ) ) );
neighbor_distances = [ sqrt( 2 ) 1 sqrt( 2 ) 1 1 sqrt( 2) 1 sqrt( 2 ) ];
itr = 1;
loop( itr ) = next_index;
itr = itr + 1;
while true
    
    curr = next_index;
    neighbors = curr + offsets;
    valids = im( neighbors ) == VALID;
    preferences = [ 7 8 5 3 2 1 4 6 ];
    next_pref = find( valids( preferences ), 1 );
    if isempty( next_pref )
        break;
    end
    next_index = neighbors( preferences( next_pref ) );
    loop( itr ) = next_index;
    right_side_distances( itr - 1 ) = neighbor_distances( preferences( next_pref ) );
    im( next_index ) = INVALID;
    itr = itr + 1;
    
end
loop = loop( 1 : end - 1 );
a = false( size( im ) );
a( loop ) = true;
t = all( a( : ) == bound_perim( : ) );

view = double( a );
view2 = double( pp.min_slice );
view2( ~isnan( view2 ) ) = 1;
view2( isnan( view2 ) ) = 0;
imtool( ( view + view2 )./ 2 );

lower_bound = pp.min_slice( loop );
upper_bound = pp.max_slice( loop );
pl = PartingLine( lower_bound, upper_bound, right_side_distances );
parting_line = round( pl.parting_line );

fh = figure();
axh = axes( fh );
axis( axh, 'square' );
hold( axh, 'on' );
x = cumsum( right_side_distances );
plot( x, lower_bound, 'k:' );
plot( x, upper_bound, 'k:' );
plot( x, pl.parting_line, 'r' );
plot( x, parting_line, 'b' );




