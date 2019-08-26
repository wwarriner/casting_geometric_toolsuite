%% SETUP
settings_file = string( which( "demo_settings.json" ) );
input_file = string( which( "bearing_block.stl" ) );
output_folder = fullfile( "C:\Users\wwarr\Desktop\a" );
user_needs = { ...
    Casting.NAME ...
    Parting.NAME ...
    Feeders.NAME ...
    Cores.NAME ...
    };

%% OPTIONS
settings = Settings( settings_file );
settings.processes.Casting.input_file = input_file;
settings.manager.output_folder = output_folder;
settings.manager.user_needs = user_needs;

%% ANALYSIS
pm = ProcessManager( settings );
pm.run();
pm.write_all(); % needs output_path defined
%summary_data = pm.generate_summary();

