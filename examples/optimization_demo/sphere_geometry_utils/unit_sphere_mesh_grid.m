function [ PHI, THETA ] = unit_sphere_mesh_grid( interpolant_resolution )

[ phi, theta ] = unit_sphere_grid_values( interpolant_resolution );
[ PHI, THETA ] = meshgrid( phi, theta );

end

