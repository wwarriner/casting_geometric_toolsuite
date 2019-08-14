%% SETUP
settings_file = string( which( "demo_options.json" ) );
input_file = string( which( "steering_column_mount.stl" ) );
output_folder = fullfile( "C:\Users\wwarr\Desktop\a" );
user_needs = { ...
    Casting.NAME ...
    CavityThinSections.NAME ...
    CavityThickSections.NAME ...
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

