%% SETUP
% reset_default_options();
option_path = which( 'demo_options.json' );
stl_path = which( 'steering_column_mount.stl' );
output_path = fullfile( 'C:\Users\wwarr\Desktop\a' );
user_needs = { ...
    Cores.NAME ...
    };

%% OPTIONS
options = Options( option_path );
keys = options.list();
options.set( 'manager.stl_file', stl_path );
options.set( 'manager.output_folder', output_path ); % needs output path defined
options.set( 'manager.user_needs', user_needs );
options.set( 'processes.thermal_profile.use', false ); % set true to compute and use thermal profile
options.set( 'processes.thermal_profile.show_dashboard', true ); % set false to hide dashboard

%% ANALYSIS
pm = ProcessManager( options );
pm.run();
pm.write(); % needs output_path defined
%summary_data = pm.generate_summary();

