function [ path, f ] = path_optimization_test()

rng( 6567860 );

%% Initial test case
% lower_bound = [ 2 1 1 0 0 5 3 3 4 4 3 2 2 ];
% upper_bound = [ 4 3 2 2 5 6 5 4 6 5 4 4 4 ];
% right_distances = [ 1 1 2 1 3 2 2 1 1 2 1 3 1 ];
% int_y = max( upper_bound ) - min( lower_bound );

%% Ambiguous case
% lower_bound = [ 1 1 ];
% upper_bound = [ 2 2 ];
% right_distances = [ 1 1 ];
% int_y = max( upper_bound ) - min( lower_bound );

%% Random case
min_x = 0;
max_x = 1200;
x_count_spline = 50;
x_count_discrete = max_x - min_x + 1;
min_y = 0;
max_y = 300;
int_y = max_y - min_y;
crossover_factor = 0.55;
min_y_lower = min_y;
max_y_lower = round( ( max_y - min_y ) * crossover_factor + min_y );
min_y_upper = round( ( max_y - min_y ) * ( 1 - crossover_factor ) + min_y );
max_y_upper = max_y;
x = linspace( min_x, max_x, x_count_spline );
lower_bound = randi( [ min_y_lower max_y_lower ], [ 1 x_count_spline ] );
upper_bound = randi( [ min_y_upper max_y_upper ], [ 1 x_count_spline ] );
wrong = upper_bound < lower_bound;
lower_bound( wrong ) = interp1( [ 0 1 ], [ 0 crossover_factor ], lower_bound( wrong ) );
upper_bound( wrong ) = interp1( [ 0 1 ], [ 1 - crossover_factor 1 ], upper_bound( wrong ) );
lower_bound = spline( x, lower_bound, min_x : max_x );
upper_bound = spline( x, upper_bound, min_x : max_x );
right_distances = 0.5 .* randn( [ 1 x_count_discrete ] ) + sqrt( 2 );
right_distances( right_distances < 1 ) = 1;

%% Optimize
[ p, f ] = parting_line_optimization( lower_bound, upper_bound, right_distances );



end

