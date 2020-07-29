function build_suitesparse( target_folder )

if nargin < 1
    here_folder = fileparts( mfilename( 'fullpath' ) );
    target_folder = fullfile( here_folder, 'out' );
end
mkdir( target_folder )
install();
bundle_files( target_folder );

end


function install()

path = pwd;
restorer = onCleanup( @()cd( path ) );
SuiteSparse_install( false );

end

