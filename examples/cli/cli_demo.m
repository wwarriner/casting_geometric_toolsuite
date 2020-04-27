%% SETUP
settings_file = string( which( "cli_settings.json" ) );
help_out = cli( "-h" );
analyze_out = cli( settings_file, "-a" );
view_out = cli( settings_file, "-v" );

