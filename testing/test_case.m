%% DEFINITIONS
ambient_id = 0;
mold_id = 1;
melt_id = 2;
element_size_in_mm = 0.4*40; % mm
space_step_in_m = element_size_in_mm / 1000; % m

%% TEST MESH GENERATION
side_length = 100;
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
center = ceil( shape ./ 2 );

%% TEST PROPERTY GENERATION
pp = PhysicalProperties( space_step_in_m );
pp.add_ambient_material( AmbientMaterial( ambient_id ) );
pp.add_material( MoldMaterial( mold_id, which( 'silica_dry.txt' ) ) );
melt = MeltMaterial( melt_id, which( 'a356.txt' ) );
melt.set_initial_temperature( 660 );
melt.set_feeding_effectivity( 0.3 );
pp.add_melt_material( melt );

conv = ConvectionProperties( ambient_id );
conv.set_ambient( mold_id, generate_air_convection() );
conv.set_ambient( melt_id, generate_air_convection() );
conv.read( mold_id, melt_id, which( 'al_sand_htc.txt' ) );
pp.set_convection( conv );

pp.prepare_for_solver();

%% LINEAR SYSTEM SOLVER
solver = modeler.LinearSystemSolver();
solver.set_tolerance( 1e-4 );
solver.set_maximum_iterations( 100 );

%% SOLIDIFICATION PROBLEM
problem = SolidificationProblem( fdm_mesh, pp, solver );
problem.set_implicitness( 1 );
problem.set_latent_heat_target_ratio( 0.05 );

%% ITERATOR
iterator = modeler.QualityBisectionIterator( problem );
iterator.set_maximum_iteration_count( 20 );
iterator.set_quality_ratio_tolerance( 0.2 );
iterator.set_time_step_stagnation_tolerance( 1e-2 );
iterator.set_initial_time_step( pp.compute_initial_time_step() );
iterator.set_printer( @fprintf );

%% RESULTS
sol_temp = pp.get_fraction_solid_temperature( 1.0 );
sol_time = SolidificationTimeResult( shape, sol_temp );
results = containers.Map( ...
    { 'solidification_times' }, ...
    { sol_time } ...
    );

%% DASHBOARD
dashboard = SolidificationDashboard( fdm_mesh, pp, solver, problem, iterator, results, center );

%% WRAPPER
manager = modeler.Manager( fdm_mesh, pp, solver, problem, iterator, results );
manager.set_dashboard( dashboard );
manager.solve();
