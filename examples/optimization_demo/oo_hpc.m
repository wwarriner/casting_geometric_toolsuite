function oo_hpc( input_path, option_path, output_mat_dir )

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

sampled_angles = generate_sphere_angles( 1000 );
count = size( sampled_angles, 1 );
samp = nan( count, numel( multiple_objective_opt() ) );
parfor i = 1 : count
    
    samp( i, : ) = objective_opt( rot_fn, sampled_angles( i, : ) );
    
end
filename = [ 'samp_' c.name ];
save( fullfile( output_mat_dir, filename ), 'samp' );

end