function mold = read_mold_material( mold_id, file_path )

data = readtable( file_path );
mold = MoldMaterial( mold_id );

[ rho_t, rho ] = remove_nans( data.rho_t, data.rho );
mold.set( RhoProperty( rho_t, rho ) );
[ cp_t, cp ] = remove_nans( data.cp_t, data.cp );
mold.set( CpProperty( cp_t, cp ) );
[ k_t, k ] = remove_nans( data.k_t, data.k );
mold.set( KProperty( k_t, k ) );
mold.set_initial_temperature( 25 );

end

