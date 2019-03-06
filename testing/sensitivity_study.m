%% DEFINITIONS
ambient_id = 0;
mold_id = 1;
melt_id = 2;
element_size_in_mm = 5; % mm

%% TEST MESH GENERATION
side_length = 100;
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


%% SENSITIVITY STUDY
implicitness = [ 0 0.5 1 ];
pcg_tol = [ 1e-3 1e-6 ];
latent_heat_target_fraction = [ 1/4 1/3 1/2 ];
quality_ratio = [ 0.01 0.1 ];

% USES DEEP LEARNING TOOLBOX
combs = combvec( ...
    1 : numel( implicitness ), ...
    1 : numel( pcg_tol ), ...
    1 : numel( latent_heat_target_fraction ), ...
    1 : numel( quality_ratio ) ...
    );

comb_count = size( combs, 2 );
data = {};
for i = 1 : comb_count
    %% MATRIX GENERATOR
    lss = LinearSystemSolver( fdm_mesh, pp );
    lss.set_solver_max_iteration_count( 100 );
    lss.set_adaptive_time_step_relaxation_parameter( 0.5 );
    lss.set_implicitness_factor( implicitness( combs( 1, i ) ) );
    lss.set_solver_tolerance( pcg_tol( combs( 2, i ) ) );
    lss.set_latent_heat_target_fraction( latent_heat_target_fraction( combs( 3, i ) ) );
    lss.set_quality_ratio_tolerance( quality_ratio( combs( 4, i ) ) );
    
    %% SOLVER
    solver = Solver( fdm_mesh, pp, lss );
    solver.turn_printing_on( @fprintf );
    solver.solve( melt_id );
    data{ i } = { ...
        solver.iteration_count, ...
        solver.solver_count, ...
        solver.pcg_count, ...
        solver.computation_times, ...
        solver.simulation_time, ...
        solver.solidification_time, ...
        solver.solidification_times ...
        };
    
end
