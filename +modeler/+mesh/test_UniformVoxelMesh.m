%% 1D
shape = [ 10 1 ];
count = prod( shape );
material_ids = ones( shape );
spacing = 0.5;
ufv = modeler.mesh.UniformVoxelMesh( material_ids, spacing );
[ conn_lhs, conn_rhs ]= ufv.get_connectivity();
[ d_lhs, d_rhs ] = ufv.get_distances();
a = ufv.get_interface_areas();
v = ufv.get_element_volumes();

%% 2D
shape = [ 10 5 ];
count = prod( shape );
material_ids = ones( shape );
spacing = 0.5;
ufv = modeler.mesh.UniformVoxelMesh( material_ids, spacing );
[ conn_lhs, conn_rhs ]= ufv.get_connectivity();
[ d_lhs, d_rhs ] = ufv.get_distances();
a = ufv.get_interface_areas();
v = ufv.get_element_volumes();

%% 3D
shape = [ 3 4 5 ];
count = prod( shape );
material_ids = ones( shape );
spacing = 0.5;
ufv = modeler.mesh.UniformVoxelMesh( material_ids, spacing );
[ conn_lhs, conn_rhs ]= ufv.get_connectivity();
[ d_lhs, d_rhs ] = ufv.get_distances();
a = ufv.get_interface_areas();
v = ufv.get_element_volumes();