function scale = compute_voxel_mesh_scale( envelope, count )

scale = ( envelope.volume / count ) .^ ( 1.0 / 3.0 );

end

