function physical_properties = generate_constant_non_melt( ...
    ambient_id, ...
    mold_id, ...
    melt_id, ...
    space_step_in_m ...
    )

ambient = AmbientMaterial( ambient_id );
ambient.set( RhoProperty( 1.225 ) ); % kg / m ^ 3
ambient.set( CpProperty( 1006 ) ); % J / kg * K
ambient.set( KProperty( 0.024 ) ); % W / m * K
ambient.set_initial_temperature( 25 ); % C

mold = MoldMaterial( mold_id );
mold.set( RhoProperty( 7800 ) ); % kg / m ^ 3
mold.set( CpProperty( 500 ) ); % J / kg * K
mold.set( KProperty( 50 ) ); % W / m * K
mold.set_initial_temperature( 25 ); % C

convection = ConvectionProperties( ambient_id );
convection.set_ambient( mold_id, HProperty( 100 ) ); % W / m ^ 2 * K
convection.set_ambient( melt_id, HProperty( 100 ) ); % W / m ^ 2 * K
convection.set( mold_id, melt_id, HProperty( 387 ) ); % W / m ^ 2 * K

physical_properties = PhysicalProperties( space_step_in_m );
physical_properties.add_ambient_material( ambient );
physical_properties.add_material( mold );
physical_properties.set_convection( convection );

end

