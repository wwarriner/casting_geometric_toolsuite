function h = read_convection( file_path )

data = readtable( file_path );
h = HProperty( data.h_t, data.h );

end

