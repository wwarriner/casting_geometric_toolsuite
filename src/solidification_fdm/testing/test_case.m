%% PHYSICAL PROPERTIES
ambient_m = AmbientMaterial();
ambient_m.id = 0;
ambient_m.initial_temperature_c = 25;

mold_m_file = 'silica_dry.txt';
mold_m = MoldMaterial( which( mold_m_file ) );
mold_m.id = 1;
mold_m.initial_temperature_c = 25;

melt_m_file = 'a356.txt';
melt_m = MeltMaterial( which( melt_m_file ) );
melt_m.id = 2;
melt_m.initial_temperature_c = 660;
melt_m.feeding_effectivity = 0.3;

pp = PhysicalProperties();
pp.add_ambient_material( ambient_m );
pp.add_material( mold_m );
pp.add_melt_material( melt_m );

conv = Convection();
conv.add_ambient( mold_m.id, HProperty( 10 ) );
conv.add_ambient( melt_m.id, HProperty( 10 ) );
conv.read( mold_m.id, melt_m.id, which( 'al_sand_htc.txt' ) );
pp.add_convection( conv );

%% GEOMETRY

%cavity = geometry.Component( which( 'bearing_block.stl' ) );
cavity = create_cube( [ -15 -15 -15 ], [ 30 30 30 ], 'cavity' );
cavity.id = melt_m.id;

mold_thickness = 10; % casting units
mold = create_cube( ...
    cavity.envelope.min_point - mold_thickness, ...
    cavity.envelope.lengths + 2 * mold_thickness, ...
    'mold' ...
    );
mold.id = mold_m.id;

%% MESHING
element_count = 1e5;
uvc = UniformVoxelCanvas( element_count );
uvc.default_body_id = mold.id;
uvc.add_body( mold );
uvc.add_body( cavity );
uvc.paint();

uvm = UniformVoxelMesh( uvc.voxels, uvc.material_ids );

%% INITIAL FIELD
u_fn = @(id,locations)pp.lookup_initial_temperatures( id ) * ones( sum( locations ), 1 );
u = uvm.apply_material_property_fn( u_fn );
%u = ufv.reshape( u );

%% TESTING
Printer.turn_print_on();
Printer.set_printer( @fprintf );

sp = SolidificationProblem( uvm, pp, melt_m.id, u );

qbi = QualityBisectionIterator( sp );
qbi.maximum_iterations = 100;
qbi.quality_target = 1/100;
qbi.quality_tolerance = 0.1;
qbi.stagnation_tolerance = 1e-2;

lp = Looper( qbi, @sp.is_finished );
lp.add_result( SolidificationTimeResult( uvm, pp, sp, qbi ) );
lp.run();

