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

oo = MultiObjectiveOrientationOptimizer( c, f, op.element_count );
objective_opt = ...
    @(rotation_fn,angles)multiple_objective_opt( rotation_fn, angles );
oo.run( objective_opt, op.population_count, op.generation_count );
filename = [ 'oo_' c.name ];
save( fullfile( output_mat_dir, filename ), 'oo' );

orthogonal_angles = [ ...
    0 0; ...
    0 -pi/2; ...
    0 pi/2; ...
    pi/2 0; ...
    pi/2 0; ...
    pi 0 ...
    ];
count = size( orthogonal_angles, 1 );
orth = nan( count, numel( multiple_objective_opt() ) );
rot_fn = @(angles) oo.rotate_objects( c, f, op.element_count, angles );
parfor i = 1 : count
    
    orth( i, : ) = objective_opt( rot_fn, orthogonal_angles( i, : ) );
    
end
filename = [ 'orth_' c.name ];
save( fullfile( output_mat_dir, filename ), 'orth' );

sampled_angles = generate_sphere_angles( 100 );
count = size( sampled_angles, 1 );
samp = nan( count, numel( multiple_objective_opt() ) );
parfor i = 1 : count
    
    samp( i, : ) = objective_opt( rot_fn, sampled_angles( i, : ) );
    
end
filename = [ 'samp_' c.name ];
save( fullfile( output_mat_dir, filename ), 'samp' );

end