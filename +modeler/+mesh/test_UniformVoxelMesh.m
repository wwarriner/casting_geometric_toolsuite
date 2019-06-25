%% 1D
shape = [ 10 1 ];
count = prod( shape );
material_ids = ones( shape );
spacing = 0.5;
ufv = modeler.mesh.UniformVoxelMesh( material_ids, spacing );
all_indices = 1 : count;
conn = ufv.get_connectivity( all_indices );
d = ufv.get_distances( all_indices );
a = ufv.get_interface_areas( all_indices );
v = ufv.get_element_volumes( all_indices );

%% 2D
shape = [ 10 5 ];
count = prod( shape );
material_ids = ones( shape );
spacing = 0.5;
ufv = modeler.mesh.UniformVoxelMesh( material_ids, spacing );
all_indices = 1 : count;
conn = ufv.get_connectivity( all_indices );
d = ufv.get_distances( all_indices );
a = ufv.get_interface_areas( all_indices );
v = ufv.get_element_volumes( all_indices );

%% 3D
shape = [ 3 4 5 ];
count = prod( shape );
material_ids = ones( shape );
spacing = 0.5;
ufv = modeler.mesh.UniformVoxelMesh( material_ids, spacing );
all_indices = 1 : count;
conn = ufv.get_connectivity( all_indices );
d = ufv.get_distances( all_indices );
a = ufv.get_interface_areas( all_indices );
v = ufv.get_element_volumes( all_indices );