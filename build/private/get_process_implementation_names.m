function names = get_process_implementation_names()

contents = get_contents( process_implementation_path() );
listing = get_files_with_extension( contents, ".m" );
[ ~, names, ~ ] = arrayfun( @(x) fileparts( x ), string( [ listing.name ] ) );
names( strcmpi( names, 'process_implementation_path' ) ) = [];

end

