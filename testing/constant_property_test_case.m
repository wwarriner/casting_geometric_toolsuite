%% DEFINITIONS
ambient_id = 0;
mold_id = 1;
melt_id = 2;
element_size_in_mm = 10; % mm

%% TEST MESH GENERATION
side_length = 50;
shape = [ ...
    side_length ...
    side_length ...
    side_length ...
    ];
[ fdm_mesh, center ] = generate_test_mesh( mold_id, melt_id, shape );

%% TEST PROPERTY GENERATION
melt_fp = which( 'AlSi9.txt' );
pp = generate_variable_test_properties( ambient_id, mold_id, melt_id, melt_fp );
% pp = generate_constant_test_properties( ambient_id, mold_id, melt_id );
pp.set_space_step( element_size_in_mm / 1000 ) % m
pp.set_max_length( shape ); % count
pp.prepare_for_solver();

%% MATRIX GENERATOR
lss = LinearSystemSolver( fdm_mesh, pp );
lss.set_implicitness_factor( 1 );
lss.set_solver_tolerance( 1e-6 );
lss.set_solver_max_iteration_count( 100 );
lss.set_adaptive_time_step_relaxation_parameter( 0.5 );
lss.set_latent_heat_target_fraction( 0.5 );
lss.set_quality_ratio_tolerance( 0.1 );

%% SOLVER
solver = Solver( fdm_mesh, pp, lss );
solver.turn_printing_on( @fprintf );
solver.turn_live_plotting_on();
solver.solve( melt_id );
