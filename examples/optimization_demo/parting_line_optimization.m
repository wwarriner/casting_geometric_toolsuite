function [ path, flatness ] = parting_line_optimization( ...
    lower_bound, ...
    upper_bound, ...
    right_distances ...
    )
%% Don't Bother Condition
if 0 < min( upper_bound ) - max( lower_bound )
    path = ( min( upper_bound ) + max( lower_bound ) ) .* 0.5;
    flatness = 1;
    return
end

%% Setup
y_bounds = [ min( lower_bound ) max( upper_bound ) ];
lb_wrapped = scale( wrap( [ lower_bound lower_bound ] ), y_bounds );
ub_wrapped = scale( wrap( [ upper_bound upper_bound ] ), y_bounds );
rd_wrapped = wrap( [ right_distances right_distances ] );
input_count = length( right_distances );
[ rd_wrapped, x_scaled, x_plot ] = prepare_x_axis_values( rd_wrapped, input_count );
path = ( ub_wrapped + lb_wrapped ) ./ 2;

%% Optimize
tic
[ opt_path, loops, flatness_values ] = optimize_path( path, lb_wrapped, ub_wrapped, rd_wrapped );
path = straighten_path( opt_path, lb_wrapped, ub_wrapped, x_scaled );
toc

%% Prepare Output
path = unscale( unwrap( path ), y_bounds );
path = path( 1 : input_count );
flatness = compute_flatness( path, right_distances );

%% Visualization
fh = figure();
axh = axes( fh );
axis( axh, 'equal' );
hold( axh, 'on' );
plot( x_plot, lower_bound( 1 : input_count ), 'k:' );
plot( x_plot, upper_bound( 1 : input_count ), 'k:' );
ph = plot( axh, x_plot, path, 'g' );
opt_path = unscale( unwrap( opt_path ), y_bounds );
ph = plot( axh, x_plot, opt_path( 1 : input_count ), 'b' );

fh = figure();
axh = axes( fh );
axis( axh, 'square' );
hold( axh, 'on' );
plot( 1 : loops, flatness_values, 'g' );

end


function [ rd_wrapped, x_scaled, x_plot ] = prepare_x_axis_values( rd_wrapped, input_count )

x = cumsum( [ 0 rd_wrapped ] );
x_scaled = x ./ max( x );
rd_wrapped = diff( x_scaled );
x_scaled = cumsum( [ 0 rd_wrapped( 1 : end - 1 ) ] );
x_plot = unwrap( x );
x_plot = x_plot( 1 : input_count );

end


function [ old_path, loop_count, flatness_values ] = optimize_path( ...
    new_path, ...
    lower_bound_wrapped, ...
    upper_bound_wrapped, ...
    right_distances_wrapped )

change = 1;
flatness_values = [];
loop_count = 0;
while change > 1e-5
    old_path = new_path;
    shifts = -compute_displacement( old_path, right_distances_wrapped );
    new_path = min( upper_bound_wrapped, max( lower_bound_wrapped, old_path + shifts ) );
    change = max( abs( new_path - old_path ) );
    flatness_values( end + 1 ) = compute_flatness( new_path, right_distances_wrapped );
    loop_count = loop_count + 1;
end

end


function d = compute_displacement( path, db )

% displacement from straight line
left_element_y = [ path( end ) path ];
left_element_y = left_element_y( 1 : end - 1 );
right_element_y = [ path path( 1 ) ];
right_element_y = right_element_y( 2 : end );

span = [ left_element_y; right_element_y ];
span_y = diff( span, 1 );
right_x = db;
left_x = circshift( db, 1 );
span_x = left_x + right_x;
slope = span_y ./ span_x;
zero_displacement_path = slope .* left_x + left_element_y;
d = path - zero_displacement_path;

end


function f = compute_flatness( path, db )

% 1D version of Ravi B and Srinivasa M N, Computer-Aided Design 22(1), pp 11-18
% Flatness criterion
h = diff( [ path path( 1 ) ] );
d = sqrt( h .^ 2 + db .^ 2 );
f = sum( d ) ./ sum( db );

end


function path = straighten_path( ...
    path, ...
    lower_bound_wrapped, ...
    upper_bound_wrapped, ...
    x_scaled )

pinned_path = ( path <= lower_bound_wrapped | upper_bound_wrapped <= path );
pinned_path_indices = find( pinned_path );
if ~isempty( pinned_path_indices )
    segment_lengths = diff( [ 0 pinned_path_indices length( path ) ] );
    right_segments = create_segments( ...
        [ pinned_path_indices pinned_path_indices( 1 ) ], ...
        segment_lengths );
    left_segments = create_segments( ...
        [ pinned_path_indices( end ) pinned_path_indices ], ...
        segment_lengths );
    x_segments = [ x_scaled x_scaled( 1 ) ];
    slopes = ( path( right_segments ) - path( left_segments ) ) ...
        ./ ( x_segments( right_segments ) - x_segments( left_segments ) );
    floating_path = ( lower_bound_wrapped < path & path < upper_bound_wrapped );
    path( floating_path ) = ...
        slopes( floating_path ) ...
        .* ( x_segments( floating_path ) - x_segments( left_segments( floating_path ) ) )...
        + path( left_segments( floating_path ) );
end

end


function segments = create_segments( ...
    pinned_path_indices, ...
    segment_lengths )

segments = cellfun( ...
    @(x,y) x .* ones( y, 1 ).', ...
    num2cell( pinned_path_indices ), ...
    num2cell( segment_lengths ), ...
    'uniformoutput', false );
segments = cell2mat( segments );

end


function x = scale( x, bounds )

interval = diff( bounds );
x = ( ( x - min( x ) ) ./ interval ) + ( min( x ) ./ interval );

end


function x = unscale( x, bounds )

interval = diff( bounds );
x = ( x - ( bounds( 1 ) ./ interval ) ) .* interval + bounds( 1 );

end


function x = wrap( x )

x = circshift( x, floor( length( x ) ./ 4 ) );

end


function x = unwrap( x )

x = circshift( x, -floor( length( x ) ./ 4 ) );

end

