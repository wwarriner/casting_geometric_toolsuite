function string = read_text_file( file )

assert( isfile( file ) );

fid = fopen( file, 'r' );
fcloser = create_file_closer( fid ); %#ok<NASGU>
string = fread( fid, '*char' )';

end

