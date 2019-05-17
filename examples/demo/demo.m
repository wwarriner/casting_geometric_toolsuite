%% SETUP
% reset_default_options();
option_path = which( 'demo_options.json' );
stl_path = which( 'bearing_block.stl' );
%output_path = fullfile( path, to, output, folder );
user_needs = { ...
    Feeders.NAME ...
    };

%% OPTIONS
options = Options( option_path );
keys = options.list();
options.set( 'manager.stl_file', stl_path );
%options.set( 'manager.output_path', output_path ); % needs output path defined
options.set( 'manager.user_needs', user_needs );
options.set( 'processes.thermal_profile.use', true ); % set true to compute and use thermal profile
options.set( 'processes.thermal_profile.show_dashboard', true ); % set false to hide dashboard

%% ANALYSIS
pm = ProcessManager( options );
pm.run();
%pm.write(); % needs output_path defined
summary_data = pm.generate_summary();

