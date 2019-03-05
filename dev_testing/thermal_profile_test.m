c = Component();
c.legacy_run( which( 'bearing_block.stl' ) );
m = Mesh();
m.legacy_run( c, 1e6 );
pp = generate_variable_test_properties( 0, 1, 2, which( 'AlSi9.txt' ) );
tp = ThermalProfile();
tp.legacy_run( m, pp );

% TODO
%  - unpad in TP so we can WS etc down the line
%  - fix computation time output in solver class