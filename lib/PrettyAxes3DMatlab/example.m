fh = figure();
axh = axes( fh );
view( 3 );
min_pt = [ -1 -1 -1 ];
max_pt = -min_pt;
pa = PrettyAxes3D( min_pt, max_pt );
pa.draw( axh );
axis( axh, 'equal', 'vis3d' );

fh = figure();
axh = axes( fh );
view( 3 );
pa2 = PrettyAxes3D();
pa2.draw();
axis( axh, 'equal', 'vis3d' );

fh = figure();
axh = axes( fh );
view( 3 );
pa3 = PrettyAxes3D( min_pt, max_pt, max_pt );
pa3.draw( axh );
axis( axh, 'equal', 'vis3d' );

fh = figure();
axh = axes( fh );
view( 3 );
pa4 = pa.copy();
pa4.set_scaling_factor( 2 );
pa4.draw( axh );
axis( axh, 'equal', 'vis3d' );

fh = figure();
axh = axes( fh );
view( 3 );
[ X, Y, Z ] = peaks( 25 );
surf( axh, X, Y, Z );
pa5 = PrettyAxes3D();
pa5.draw( axh );
axis( axh, 'square', 'vis3d' );

fh = figure();
axh = axes( fh );
view( 3 );
surf( axh, X, Y, Z );
pa6 = PrettyAxes3D();
pa6.set_colors( repmat( [ 0 0 0 ], [ 3 1 ] ) );
pa6.set_pos_neg_labels( 'PN' );
pa6.set_axis_labels( 'UVW' );
pa6.draw( axh );
axis( axh, 'square', 'vis3d' );