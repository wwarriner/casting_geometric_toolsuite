function physical_properties = generate_constant_test_properties( ambient_id, mold_id, melt_id )

mold_rho = RhoProperty( 7800 ); % kg / m ^ 3
mold_cp = CpProperty( 500 ); % J / kg * K
mold_k = KProperty( 50 ); % W / m * K
mold = MoldMaterial( mold_id );
mold.set( mold_rho, mold.RHO_INDEX );
mold.set( mold_cp, mold.CP_INDEX );
mold.set( mold_k, mold.K_INDEX );
mold.set_initial_temperature( 25 ); % C

melt_rho = RhoProperty( 2700 ); % kg / m ^ 3
melt_cp = CpProperty( 900 ); % J / kg * K
melt_k = KProperty( 200 ); % W / m * K
melt_fs_val = [ 1.0 0.0 ]; % ratio
melt_fs_temp = [ 659.9 660.1 ]; % C
melt_fs = FsProperty( melt_fs_temp, melt_fs_val );
melt = MeltMaterial( melt_id );
melt.set( melt_rho, melt.RHO_INDEX );
melt.set( melt_cp, melt.CP_INDEX );
melt.set( melt_k, melt.K_INDEX );
melt.set( melt_fs, melt.FS_INDEX );
melt.set_feeding_effectivity( 0.5 ); % ratio
melt.set_initial_temperature( 700 ); % C

ambient_mold_h = HProperty( 100 ); % W / m ^ 2 * K
ambient_melt_h = HProperty( 100 ); % W / m ^ 2 * K
mold_melt_h = HProperty( 387 ); % W / m ^ 2 * K
convection = ConvectionProperties( ambient_id );
convection.set_ambient( mold_id, ambient_mold_h );
convection.set_ambient( melt_id, ambient_melt_h );
convection.set( mold_id, melt_id, mold_melt_h );

physical_properties = PhysicalProperties();
physical_properties.set_ambient_temperature( 25 ) % C;
physical_properties.add_material( mold, mold_id );
physical_properties.add_melt_material( melt, melt_id );
physical_properties.set_convection( convection );

end

