function [ axhs, phs ] = test_plot_setup()

figure();
axhs( 1 ) = subplot( 3, 1, 1 );
hold( axhs( 1 ), 'on' );
axhs( 2 ) = subplot( 3, 1, 2 );
hold( axhs( 2 ), 'on' );
axhs( 3 ) = subplot( 3, 1, 3 );
hold( axhs( 3 ), 'on' );
phs = [];

end

