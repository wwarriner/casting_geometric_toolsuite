function generate_sphere_angle_csv( outdir )

if nargin < 1
    outdir = '.';
end

MEAN_SEPARATION_DEGREES = 5;
sphere_angles = generate_sphere_angles( MEAN_SEPARATION_DEGREES, 'octahedral' );
csvwrite( fullfile( outdir, 'sphere_angles.csv' ), sphere_angles );

end

