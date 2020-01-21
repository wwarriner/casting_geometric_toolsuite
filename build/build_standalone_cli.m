function build_standalone_cli()

target_folder = get_target_folder( "cli" );
prepare_folder( target_folder )

cache_folder = fullfile( target_folder, "cache" );
prepare_folder( cache_folder );

build_casting_geometric_toolsuite( cache_folder );



end

