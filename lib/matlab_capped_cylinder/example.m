%% Figure
fh = figure( 'color', 'w' );

%% Quadrilateral
fv = capped_cylinder( 2, 5, 60 );
axh = subplot( 1, 2, 1 );
axh.XLim = [ -2 2 ];
axh.YLim = [ -2 2 ];
axh.ZLim = [ 0 5 ];
patch( fv, 'facecolor', 'r' );
axis equal;
axis vis3d;
view( [ 45 30 ] );
camzoom( 0.75 );

%% Triangle
fv = capped_cylinder( 2, 5, 60, 'triangles' );
axh = subplot( 1, 2, 2 );
axh.XLim = [ -2 2 ];
axh.YLim = [ -2 2 ];
axh.ZLim = [ 0 5 ];
patch( fv, 'facecolor', 'g' );
axis equal;
axis vis3d;
view( [ 45 30 ] );
camzoom( 0.75 );
