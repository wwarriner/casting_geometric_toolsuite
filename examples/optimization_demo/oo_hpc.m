function oo_hpc( input_path, option_path, csv_path, output_mat_dir )

index = 0;%str2double( getenv( 'SLURM_ARRAY_TASK_ID' ) );
angles = dlmread( csv_path, ',', [ index 0 index 1 ] );

op = Options( 'option_defaults.json', option_path, input_path, '' );

r = rotator( angles );

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

cr = c.rotate( r );
mr = Mesh();
mr.legacy_run( cr, op.element_count );
fr = f.rotate( r, mr );



rot_fn = @(angles) deal( cr, mr, fr );
%sampled_angles = generate_sphere_angles( 1000 );
%count = size( sampled_angles, 1 );
%samp = nan( count, numel( multiple_objective_opt() ) );
%parfor i = 1 : count
    
samp = multiple_objective_opt( rot_fn, angles );
    
%end
filename = [ 'samp_' c.name '_' sprintf( '%i', index ) '.mat' ];
save( fullfile( output_mat_dir, filename ), 'samp' );

end