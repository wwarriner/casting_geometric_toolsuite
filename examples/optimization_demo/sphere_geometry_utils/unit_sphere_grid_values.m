function [ phis, thetas ] = unit_sph_grid_values( resolution )

[ phi_range, theta_range ] = unit_sph_ranges();

phi_resolution = 2 * resolution + 1;
phis = linspace( phi_range( 1 ), phi_range( 2 ), phi_resolution );

theta_resolution = resolution + 1;
thetas = linspace( theta_range( 1 ), theta_range( 2 ), theta_resolution );

end

