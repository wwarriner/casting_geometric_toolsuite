function build_suitesparse()

SuiteSparse_install( false );

here_folder = fileparts( mfilename( 'fullpath' ) );
target_folder = fullfile( here_folder, 'out' );
if isfolder( target_folder )
    rmdir( target_folder, 's' )
end
mkdir( target_folder )
bundle_files( target_folder );

end

