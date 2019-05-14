function melt = read_melt_material( melt_id, file_path )

data = readtable( file_path );
melt = MeltMaterial( melt_id );

[ rho_t, rho ] = remove_nans( data.rho_t, data.rho );
melt.set( RhoProperty( rho_t, rho ) );
[ cp_t, cp ] = remove_nans( data.cp_t, data.cp );
melt.set( CpProperty( cp_t, cp ) );
[ k_t, k ] = remove_nans( data.k_t, data.k );
melt.set( KProperty( k_t, k ) );
[ fs_t, fs ] = remove_nans( data.fs_t, data.fs );
melt.set( FsProperty( fs_t, fs ) );
initial_temp = compute_default_initial_melt_temperature( melt );
melt.set_initial_temperature( initial_temp );
melt.set_feeding_effectivity( 0.5 );

end

