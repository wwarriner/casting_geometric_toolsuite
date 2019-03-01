function [ fh, axhs, phs ] = test_plot_setup( ...
    temperature_range, ...
    bounding_box_lengths, ...
    element_count ...
    )

fh = figure();
fh.Position = [ 50 50 800 800 ];
phs = [];

%% TEMPERATURE PROFILES
axhs( 1 ) = subplot( 6, 2, 1 );
hold( axhs( 1 ), 'on' );
axhs( 1 ).YLim = temperature_range;
axhs( 1 ).XLim = [ 0 bounding_box_lengths( 1 ) ];

axhs( 2 ) = subplot( 6, 2, 3 );
hold( axhs( 2 ), 'on' );
axhs( 2 ).YLim = temperature_range;
axhs( 2 ).XLim = [ 0 bounding_box_lengths( 2 ) ];

axhs( 3 ) = subplot( 6, 2, 5 );
hold( axhs( 3 ), 'on' );
axhs( 3 ).YLim = temperature_range;
axhs( 3 ).XLim = [ 0 bounding_box_lengths( 3 ) ];

%% STATISTICAL TEMPERATURE CURVES
axhs( 4 ) = subplot( 6, 2, [ 2 4 6 ] );
hold( axhs( 4 ), 'on' );
axhs( 4 ).YLim = temperature_range;

%% dKdT HISTOGRAM
axhs( 5 ) = subplot( 6, 2, 7 : 12 );
hold( axhs( 4 ), 'on' );
axhs( 5 ).YLim = [ 1 element_count ];
axhs( 5 ).YScale = 'log';


end

