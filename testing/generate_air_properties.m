function ambient = generate_air_properties( ambient_id )

ambient = AmbientMaterial( ambient_id );
ambient.set( RhoProperty( 1.225 ) ); % kg / m ^ 3
ambient.set( CpProperty( 1006 ) ); % J / kg * K
ambient.set( KProperty( 0.024 ) ); % W / m * K
ambient.set_initial_temperature( 25 ); % C

end

