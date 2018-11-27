load( 'base_plate_data.mat' );
load( 'bearing_block_data.mat' );
load( 'steering_column_mount_data.mat' );

results_table = base_plate_data;
figure_resolution_px = 600;
usra = UnitSphereResponseAxes();
usrd = UnitSphereResponseData( ...
    results_table, ...
    figure_resolution_px ...
    );
usrp = UnitSphereResponsePlot( usrd, usra, figure_resolution_px );
