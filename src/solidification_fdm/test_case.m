%% PHYSICAL PROPERTIES
ambient_m = AmbientMaterial();
ambient_m.id = 0;
ambient_m.initial_temperature_c = 25;

melt_m_file = 'a356.txt';
melt_m = MeltMaterial( which( melt_m_file ) );
melt_m.id = 2;
melt_m.initial_temperature_c = 660;
melt_m.feeding_effectivity = 0.3;

mold_m_file = 'silica_dry.txt';
mold_m = MoldMaterial( which( mold_m_file ) );
mold_m.id = 1;
mold_m.initial_temperature_c = 25;

smp = SolidificationMaterialProperties();
smp.add_ambient( ambient_m );
smp.add_melt( melt_m );
smp.add( mold_m );

sip = SolidificationInterfaceProperties();
sip.add_ambient( melt_m.id, HProperty( 10 ) );
sip.add_ambient( mold_m.id, HProperty( 10 ) );
sip.read( melt_m.id, mold_m.id, which( 'al_sand_htc.txt' ) );

%% GEOMETRY

stl = StlFile( which( 'bearing_block.stl' ) );
cavity = Body( stl.fv );
%cavity = create_cube( [ -15 -15 -15 ], [ 30 30 30 ], 'cavity' );
cavity.id = melt_m.id;

mold_thickness = 10; % casting units
mold = create_cube( ...
    cavity.envelope.min_point - mold_thickness, ...
    cavity.envelope.lengths + 2 * mold_thickness, ...
    'mold' ...
    );
mold.id = mold_m.id;

%% MESHING
element_count = 1e3;
uvc = UniformVoxelCanvas( element_count );
uvc.default_body_id = mold.id;
uvc.add_body( mold );
uvc.add_body( cavity );
uvc.paint();

uvm = UniformVoxelMesh( uvc.voxels, uvc.material_ids );

%% INITIAL FIELD
u_fn = @(id,locations)smp.lookup_initial_temperatures( id ) * ones( sum( locations ), 1 );
u = uvm.apply_material_property_fn( u_fn );
%u = ufv.reshape( u );

%% TESTING
Printer.turn_print_on();
Printer.set_printer( @fprintf );

sp = SolidificationProblem( uvm, smp, sip, melt_m.id, u );

qbi = QualityBisectionIterator( sp );
qbi.maximum_iterations = 100;
qbi.quality_target = 1/1000;
qbi.quality_tolerance = 0.1;
qbi.stagnation_tolerance = 1e-2;

ct = CompressedTemperature( qbi, sp );

lp = Looper( qbi, @sp.is_finished );
lp.add_result( SolidificationTimeResult( uvm, sp, qbi ) );
lp.run();