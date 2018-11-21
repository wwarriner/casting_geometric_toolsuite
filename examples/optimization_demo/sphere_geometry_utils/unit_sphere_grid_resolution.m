function [ phi, theta ] = unit_sphere_grid_resolution( resolution )

phi = 2 * resolution + 1;
theta = make_odd( resolution );

end

