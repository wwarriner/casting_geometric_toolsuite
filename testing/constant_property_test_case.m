%% DEFINITIONS
ambient_id = 0;
mold_id = 1;
melt_id = 2;
element_size_in_mm = 1; % mm
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
melt = read_melt_material( melt_id, which( 'cf3mn.txt' ) );
melt.set_initial_temperature( 1600 );
melt.set_feeding_effectivity( 0.3 );
pp.add_melt_material( melt );

conv = ConvectionProperties( ambient_id );
conv.set_ambient( mold_id, generate_air_convection() );
conv.set_ambient( melt_id, generate_air_convection() );
conv.set( mold_id, melt_id, read_convection( which( 'steel_sand_htc.txt' ) ) );
pp.set_convection( conv );

pp.prepare_for_solver();

%% MATRIX GENERATOR
lss = LinearSystemSolver( fdm_mesh, pp );
lss.set_solver_tolerance( 1e-3 );
lss.set_implicitness( 1 );
lss.set_solver_max_iteration_count( 100 );
lss.set_latent_heat_target_fraction( 0.25 );
lss.set_quality_ratio_tolerance( 0.1 );

%% SOLVER
solver = FdmSolver( fdm_mesh, pp, lss );
solver.turn_printing_on( @fprintf );
solver.turn_live_plotting_on();
solver.solve( melt_id );
solver.display_computation_time_summary();
