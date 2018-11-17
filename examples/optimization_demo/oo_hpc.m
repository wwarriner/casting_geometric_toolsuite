function oo_hpc( input_path, option_path, angles, index, output_mat_dir )

op = Options( 'option_defaults.json', option_path, input_path, '' );

c = Component();
c.legacy_run( input_path );
m = Mesh();
m.legacy_run( c, op.element_count );
e = EdtProfile();
e.legacy_run( m );
s = Segmentation();
s.legacy_run( e, m );
f = Feeders();
f.legacy_run( s, m );

r = rotator( angles );
cr = c.rotate( r );
mr = Mesh();
mr.legacy_run( cr, op.element_count );
fr = f.rotate( r, mr );



rotation_function = @(angles) deal( cr, mr, fr );    
objectives = multiple_objective_opt( rotation_function, angles );
objectives = array2table( objectives );
[ ~, titles ] = multiple_objective_opt();
objectives.Properties.VariableNames = titles;

filename = [ 'objectives_' c.name '_' sprintf( '%i', index ) '.csv' ];
writetable( objectives, fullfile( output_mat_dir, filename ) );

end