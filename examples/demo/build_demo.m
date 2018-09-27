function res_path = build_demo()
%% COMMON STUFF
this_path = fileparts( mfilename( 'fullpath' ) );
res_path = fullfile( this_path, 'res' );

%% BUILD BACKEND
build_backend();
copy_backend_resources( res_path );

end