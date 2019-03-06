function physical_properties = generate_variable_test_properties( ambient_id, mold_id, melt_id, melt_filepath )

physical_properties = generate_constant_non_melt( ambient_id, mold_id, melt_id );

data = readtable( melt_filepath );
melt = MeltMaterial( melt_id );
melt.set( RhoProperty( data.rho_t, data.rho ) );
melt.set( CpProperty( data.cp_t, data.cp ) );
melt.set( KProperty( data.k_t, data.k ) );
melt_fs_t = [ 560 600 605 630 ];
melt_fs_v = [ 1.0 0.3 0.2 0.0 ];
melt.set( FsProperty( melt_fs_t, melt_fs_v ) );
melt.set_feeding_effectivity( 0.5 );
melt.set_initial_temperature( 700 );

physical_properties.add_melt_material( melt );

end

