function string = write_file( path, string )

fid = fopen( path, 'W' );
fcloser = create_file_closer( fid ); %#ok<NASGU>
string = fprintf( fid, '%s', string );

end

