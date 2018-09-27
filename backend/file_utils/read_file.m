function string = read_file( path )

fid = fopen( path, 'r' );
fcloser = create_file_closer( fid ); %#ok<NASGU>
string = fread( fid, '*char' )';

end

