%% SETUP
settings_file = string( which( "demo_settings.json" ) );
input_file = string( which( "base_plate.stl" ) ); % change me to your file location!
output_folder = fullfile( "C:\Users\wwarr\Desktop\a" ); % change me to your desired output folder!
user_needs = { ...
    Casting.NAME ...
    CavityThinSections.NAME ...
    MoldThinSections.NAME ...
    Undercuts.NAME ...
    GeometricProfile.NAME ...
    IsolatedSections.NAME ...
    Parting.NAME ...
    ThermalProfile.NAME ...
    Feeders.NAME
    };

%% OPTIONS
settings = Settings( settings_file );
settings.processes.Casting.input_file = input_file;
settings.manager.output_folder = output_folder;
settings.manager.user_needs = user_needs;
settings.manager.overwrite_output = true;

% set below to change mesh density: higher value means better resolution, but
% slower computation and more memory usage.
settings.processes.Mesh.desired_element_count = 1e6;
% set below to true if you want physical solidification
% false for geometric approximation
% WARNING! memory usage is currently very high! 1e7 uses ~20GB peak.
settings.processes.IsolatedSections.use_thermal_profile = true;

%% ANALYSIS
pm = ProcessManager( settings );
pm.overwrite_output = true; % set to true to allow overwrite
pm.prepare_output_files();
pm.run();
pm.write_all(); % needs output_path defined
%summary_data = pm.generate_summary();

