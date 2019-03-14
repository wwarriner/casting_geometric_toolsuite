c = Component();
c.legacy_run( which( 'bearing_block.stl' ) );
m = Mesh();
m.legacy_run( c, 1e6 );
tp = ThermalProfile();
tp.legacy_run( m );

% TODO
%  - unpad in TP so we can WS etc down the line
%  - fix computation time output in solver class