function [ objectives, TITLES ] = multiple_objective_opt( rotation_function, angles )

%angles = [ -0.011560 0.693333  ];
%fprintf( 1, '%f ', angles );
%fprintf( 1, '\n' );

% Constants
DIM = 3;
UP = 'up';

% visualization information
CATEGORICAL_METRIC_COUNT = 2;
CONTINUOUS_METRIC_COUNT = 11;
METRIC_COUNT = CATEGORICAL_METRIC_COUNT + CONTINUOUS_METRIC_COUNT;
TITLES = { ...
    'pp_count' ...
    'uc_count' ...
    'pp_projected_area_reciprocal' ...
    'pp_flatness' ...
    'pp_draw' ...
    'draft_metric' ...
    'uc_volume' ...
    'fd_inaccessibility_max' ...
    'fd_total_intersection_volume' ...
    'fd_total_interface_area' ...
    'wf_gating_opportunity_reciprocal' ...
    'wf_worst_drop_max' ...
    'flask_height' ...
    };
if nargin == 0
    objectives = cell( METRIC_COUNT, 1 );
    objectives( : ) = { 'natural' };
    objectives( 1 : CATEGORICAL_METRIC_COUNT ) = { 'nearest' };
    assert( numel( objectives ) == numel( TITLES ) );
    return;
end

% setup
cleanup_tasks = onCleanup( @() Print.turn_print_on() );
Print.turn_print_off();

% metric computation
[ c, m, f ] = rotation_function( angles );
uc = Undercuts();
uc.legacy_run( m, DIM );
pp = PartingPerimeter();
pp.legacy_run( m, DIM, true );
wf = Waterfall();
wf.legacy_run( m, pp, UP );

% output
categorical_metrics = [ ...
    pp.count, ...
    uc.count ...
    ];
assert( CATEGORICAL_METRIC_COUNT == length( categorical_metrics ) );
% USED
% projected area (maximized)
% flatness (maximized)
% draw (minimized)
% draft (ignores undercut surfaces, binary, minimized insufficient area)
% undercuts (volume, minimized)
% undercuts (count, minimized)
% feeder accessibility (maximized)
% waterfall (minimized)
% flask height (minimized)
% UNUSED DUE TO TECHNICAL DIFFICULTIES
% dimensional stability, flash, machined volume
continuous_metrics = [ ...
    ...% projected area related
    1 ./ pp.projected_area ...
    ... % flatness related
    pp.flatness ...
    ...% draw related
    pp.draw ...
    ...% draft related
    ...% this is still too immature to use reliably I think
    ...% we only want draft surfaces not touching cores
    ...% even ignoring that, straight surfaces are going to cause issues
    ...% which means common parts (not-near-net-shape) which have no draft
    ...% will be penalized and suggested orientations will be slightly askew
    c.draft_metric ...
    ...% undercut related
    uc.volume ...
    ...% feeder accessibility related
    max( 1 - f.get_accessibility_ratios() ) ...
    f.get_total_intersection_volume() ...
    f.get_total_interface_area() ...
    ...% waterfall related
    1 ./ wf.gating_opportunity ...
    max( wf.worst_drop( wf.worst_drop > 0 ) ) ...
    ...% flask height related
    f.get_total_rigged_height( DIM );
    ];
assert( CONTINUOUS_METRIC_COUNT == length( continuous_metrics ) );
objectives = [ categorical_metrics continuous_metrics ];

% tracking
fprintf('\b|\n');

end

