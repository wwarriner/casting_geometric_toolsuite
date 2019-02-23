c = Component();
c.legacy_run( which( 'bearing_block.stl' ) );
m = Mesh();
m.legacy_run( c, 1e6 );
pp = generate_constant_test_properties( 0, 1, 2 );
time_step_in_s = 0.01;
tp = ThermalProfile();
tp.legacy_run( m, pp, time_step_in_s );

% TODO
%  - unpad in TP so we can WS etc down the line
%  - fix computation time output in solver class