function reset_default_options()

demo_folder = fileparts( mfilename( 'fullpath' ) );
res_folder = fullfile( demo_folder, 'res' );
demo_options_file = fullfile( res_folder, 'hpc_options.json' );
copyfile( which( 'option_defaults.json' ), demo_options_file );

end

