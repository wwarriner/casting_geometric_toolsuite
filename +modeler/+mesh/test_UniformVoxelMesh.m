%% 1D
% shape = [ 10 1 ];
% count = prod( shape );
% material_ids = randi( 3, shape );
% spacing = 2;
% ufv = modeler.mesh.UniformVoxelMesh( material_ids, spacing );
% conn = ufv.get_connectivity();
% ib = ufv.get_internal_boundaries();
% eb = ufv.get_external_boundaries();
% [ d_lhs, d_rhs ] = ufv.get_distances();
% a = ufv.get_interface_areas();
% v = ufv.get_element_volumes();

%% 2D
% shape = [ 10 5 ];
% count = prod( shape );
% material_ids = randi( 3, shape );
% spacing = 2;
% ufv = modeler.mesh.UniformVoxelMesh( material_ids, spacing );
% conn = ufv.get_connectivity();
% ib = ufv.get_internal_boundaries();
% eb = ufv.get_external_boundaries();
% [ d_lhs, d_rhs ] = ufv.get_distances();
% a = ufv.get_interface_areas();
% v = ufv.get_element_volumes();

%% 3D
rng( 314159 )
%cavity = geometry.shapes.create_cube( [ -1 -1 -1 ], [ 2 2 2 ], 'cavity' );
%cavity.assign_id( 1 );
cavity = geometry.Component( which( 'bearing_block.stl' ) );
cavity.assign_id( 1 );
mold = geometry.shapes.create_cube( cavity.envelope.min_point - 25, cavity.envelope.lengths + 50, 'mold' );
mold.assign_id( 2 );

element_count = 1e5;
ufv = modeler.mesh.UniformVoxelMesh( element_count );
ufv.add_component( mold );
ufv.add_component( cavity );
ufv.build();
ufv.assign_uniform_external_boundary_id( 1 );
