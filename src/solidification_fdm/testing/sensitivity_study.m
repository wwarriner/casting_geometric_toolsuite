function sensitivity_study()
%% SETUP
diary( 'sensitivity_study.txt' );
cleanerupper = onCleanup( @()diary( 'off' ) );

%% DEFINITIONS
ambient_id = 0;
mold_id = 1;
melt_id = 2;

%% SENSITIVITY STUDY
side_length = [ 25 50 100 200 ];
element_size_in_mm = { @(sl)100/sl, @(sl)500/sl, @(sl)1000/sl };
implicitness = [ 0 0.5 1 ];
pcg_tol = [ 1e-3 1e-6 ];
latent_heat_target_fraction = [ 1/4 1/3 1/2 ];
quality_ratio = [ 0.01 0.1 ];

% USES DEEP LEARNING TOOLBOX
combs = combvec( ...
    1 : numel( side_length ), ...
    1 : numel( element_size_in_mm ), ...
    1 : numel( implicitness ), ...
    1 : numel( pcg_tol ), ...
    1 : numel( latent_heat_target_fraction ), ...
    1 : numel( quality_ratio ) ...
    );

comb_count = size( combs, 2 );
data = {};
for i = 1 : comb_count
    %% PARAMETERS
    sl = side_length( combs( 1, i ) );
    elsmm_fn = element_size_in_mm{ combs( 2, i ) };
    elsmm = elsmm_fn( sl );
    impl = implicitness( combs( 3, i ) );
    ptol = pcg_tol( combs( 4, i ) );
    lhtf = latent_heat_target_fraction( combs( 5, i ) );
    qrtol = quality_ratio( combs( 6, i ) );
    
    %% TEST MESH GENERATION
    shape = [ sl sl sl ];
    fdm_mesh = generate_test_mesh( mold_id, melt_id, shape );

    %% TEST PROPERTY GENERATION
    melt_fp = which( 'AlSi9.txt' );
    pp = generate_variable_test_properties( ambient_id, mold_id, melt_id, melt_fp );
    % pp = generate_constant_test_properties( ambient_id, mold_id, melt_id );
    pp.set_space_step( elsmm / 1000 ); % m
    pp.set_max_length( shape ); % count
    pp.prepare_for_solver();
    
    %% UPDATE
    fprintf( 'STARTING COMBINATION %i\n', i );
    fprintf( 'Side length: %i\n', sl );
    fprintf( 'Element size in mm: %.1f\n', elsmm );
    fprintf( 'Implicitness: %.1f\n', impl );
    fprintf( 'PCG Tolerance: %.1e\n', ptol );
    fprintf( 'Latent Heat Target Fraction: %.2f\n', lhtf );
    fprintf( 'Quality Ratio Tolerance: %.2f\n', qrtol );
    
    %% MATRIX GENERATOR
    lss = LinearSystemSolver( fdm_mesh, pp );
    lss.set_solver_max_iteration_count( 100 );
    lss.set_adaptive_time_step_relaxation_parameter( 0.5 );
    lss.set_implicitness_factor( impl );
    lss.set_solver_tolerance( ptol );
    lss.set_latent_heat_target_fraction( lhtf );
    lss.set_quality_ratio_tolerance( qrtol );
    
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

end


