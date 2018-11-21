function [ phis, thetas ] = unit_sphere_grid_values( resolution )

[ phi_range, theta_range ] = unit_sphere_ranges();
[ phi_resolution, theta_resolution ] = unit_sphere_grid_resolution( resolution );
phis = linspace( phi_range( 1 ), phi_range( 2 ), phi_resolution );
thetas = linspace( theta_range( 1 ), theta_range( 2 ), theta_resolution );

end

