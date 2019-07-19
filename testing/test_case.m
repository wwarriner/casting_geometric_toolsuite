%cavity = geometry.Component( which( 'bearing_block.stl' ) );
cavity = geometry.shapes.create_cube( [ -0.015 -0.015 -0.015 ], [ 0.03 0.03 0.03 ], 'cavity' );
cavity_id = 1;
cavity.assign_id( cavity_id );

mold_thickness = 0.010; % stl units
mold = geometry.shapes.create_cube( ...
    cavity.envelope.min_point - mold_thickness, ...
    cavity.envelope.lengths + 2 * mold_thickness, ...
    'mold' ...
    );
mold_id = 2;
mold.assign_id( mold_id );

element_count = 1e5;
ufv = mesh.UniformVoxelMesh( element_count );
ufv.default_component_id = mold.id;
ufv.add_component( mold );
ufv.add_component( cavity );
ufv.build();
ufv.assign_uniform_external_boundary_id( 1 );

%% TEST PROPERTY GENERATION
ambient_id = 0;
space_step_in_m = 0.005; % m
pp = PhysicalProperties( space_step_in_m );
pp.add_ambient_material( AmbientMaterial( ambient_id ) );
pp.add_material( MoldMaterial( mold_id, which( 'silica_dry.txt' ) ) );
melt = MeltMaterial( cavity_id, which( 'a356.txt' ) );
melt.set_initial_temperature( 660 );
melt.set_feeding_effectivity( 0.3 );
pp.add_melt_material( melt );

conv = ConvectionProperties( ambient_id );
conv.set_ambient( mold_id, generate_air_convection() );
conv.set_ambient( cavity_id, generate_air_convection() );
conv.read( mold_id, cavity_id, which( 'al_sand_htc.txt' ) );
pp.set_convection( conv );

pp.prepare_for_solver();

%% INITIAL FIELD
u_fn = @(id,locations)pp.lookup_initial_temperatures( id ) * ones( sum( locations ), 1 );
u = ufv.apply_material_property_fn( u_fn );
%u = ufv.reshape( u );

%% TESTING
utils.Printer.turn_print_on();
utils.Printer.set_printer( @fprintf );

sk = problem.kernel.SolidificationKernel( pp, ufv, u );
lss = solver.LinearSystemSolver();

smk = problem.kernel.SolidificationMetaKernel( sk, lss, pp, cavity_id );

qbi = modeler.QualityBisectionIterator( smk );
qbi.maximum_iterations = 100;
qbi.quality_tolerance = 0.2;
qbi.stagnation_tolerance = 1e-2;
qbi.initial_time_step = pp.compute_initial_time_step();
qbi.iterate();

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
