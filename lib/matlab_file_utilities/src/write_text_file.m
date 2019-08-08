function write_text_file( file, string )

assert( ~isfolder( file ) );

fid = fopen( file, 'W' );
fcloser = create_file_closer( fid ); %#ok<NASGU>
fprintf( fid, '%s', string );

end

