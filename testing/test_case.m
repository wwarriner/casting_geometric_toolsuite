%% DEFINITIONS
ambient_id = 0;
mold_id = 1;
melt_id = 2;
element_size_in_mm = 0.4*40; % mm
space_step_in_m = element_size_in_mm / 1000; % m

%% TEST MESH GENERATION
side_length = 25;
shape = [ ...
    side_length ...
    side_length ...
    side_length ...
    ];
meltwall = 30;
mold = 25;
total = ( meltwall + mold * 2 );
melt_ratio = meltwall ./ total;
fdm_mesh = generate_test_mesh( mold_id, melt_id, shape, melt_ratio );

%% TEST PROPERTY GENERATION
ambient = generate_air_properties( ambient_id );
pp = PhysicalProperties( space_step_in_m );
pp.add_ambient_material( generate_air_properties( ambient_id ) );
pp.add_material( read_mold_material( mold_id, which( 'silica_dry.txt' ) ) );
melt = read_melt_material( melt_id, which( 'a356.txt' ) );
melt.set_initial_temperature( 700 );
melt.set_feeding_effectivity( 0.3 );
pp.add_melt_material( melt );

conv = ConvectionProperties( ambient_id );
conv.set_ambient( mold_id, generate_air_convection() );
conv.set_ambient( melt_id, generate_air_convection() );
conv.set( mold_id, melt_id, read_convection( which( 'al_sand_htc.txt' ) ) );
pp.set_convection( conv );

pp.prepare_for_solver();

%% LINEAR SYSTEM SOLVER
solver = LinearSystemSolver();
solver.set_tolerance( 1e-4 );
solver.set_maximum_iterations( 100 );

%% SOLIDIFICATION PROBLEM
problem = SolidificationProblem( fdm_mesh, pp, solver );
problem.set_implicitness( 1 );
problem.set_latent_heat_target_ratio( 0.05 );

%% ITERATOR
iterator = QualityBisectionIterator( problem );
iterator.set_maximum_iteration_count( 20 );
iterator.set_quality_ratio_tolerance( 0.2 );
iterator.set_time_step_stagnation_tolerance( 0.01 );
iterator.set_initial_time_step( pp.compute_initial_time_step() );

%% RESULTS
sol_temp = pp.get_fraction_solid_temperature( 1.0 );
sol_time = SolidificationTimeResult( shape, sol_temp );
results = containers.Map( ...
    { 'solidification_times' }, ...
    { sol_time } ...
    );

%% WRAPPER
manager = FdmManager( fdm_mesh, pp, solver, problem, iterator, results );
manager.solve();
