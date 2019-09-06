%% MODE
DIMENSION_COUNT = 1;
ANALYSIS_DIMENSION = 1;

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

%stl = StlFile( which( 'bearing_block.stl' ) );
%cavity = Body( stl.fv );
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
switch DIMENSION_COUNT
    case 1
        axs = 1 : 3;
        axs( ANALYSIS_DIMENSION ) = [];
        envelope = mold.envelope.collapse_to( axs );
    case 2
        envelope = mold.envelope.collapse_to( ANALYSIS_DIMENSION );
    case 3
        envelope = mold.envelope;
    otherwise
        assert( false )
end

ELEMENT_COUNT = 1e2;
uvc = UniformVoxelCanvas( ELEMENT_COUNT, envelope );
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

%ct = CompressedTemperature( qbi, sp );

lp = Looper( qbi, @sp.is_finished );
str = SolidificationTimeResult( uvm, sp, qbi );
lp.add_result( str );
lp.run();

%% PLOTTING
fh = figure();
patch_axh = axes( fh );
hold( patch_axh, 'on' );
ph = patch( patch_axh, cavity.fv );
ph.FaceColor = [ 0.5 1.0 0.5 ];
ph.EdgeColor = 'none';
ph = patch( patch_axh, mold.fv );
ph.FaceColor = [ 0.7 0.0 0.7 ];
ph.FaceAlpha = 0.2;
ph.EdgeColor = 'none';
axis( patch_axh, 'equal', 'vis3d' );
view( patch_axh, 3 );
light( patch_axh );

rr = squeeze( uvm.reshape( lp.results{ 1 }.modulus ) );
rr( isnan( rr ) ) = 0;

switch DIMENSION_COUNT
    case 1
        x = [ envelope.min_point; envelope.max_point ];
        ph = plot3( patch_axh, x( :, 1 ), x( :, 2 ), x( :, 3 ) );
        ph.LineWidth = 5;
        ph.Color = [ 0 0 0 ];
        
        fh = figure();
        axh = axes( fh );
        hold( axh, 'on' );
        xl = [ ...
            envelope.min_point( ANALYSIS_DIMENSION ), ...
            envelope.max_point( ANALYSIS_DIMENSION ) ...
            ];
        xx = linspace( ...
            xl( 1 ), ...
            xl( 2 ), ...
            numel( rr ) ...
            );
        plot( axh, xx, rr );
        axh.XLim = xl;
        axh.YLim( 1 ) = 0;
        yyaxis( axh, 'right' );
        plot( axh, xx, squeeze( uvc.voxels.values ) );
        axh.YLim( 1 ) = 1;
        axis( axh, 'square' );
    case 2
        axs = 1 : 3;
        axs( ANALYSIS_DIMENSION ) = [];
        x = [ envelope.min_point; envelope.max_point ];
        box( :, axs( 1 ) ) = [ ...
            x( 1, axs( 1 ) )
            x( 1, axs( 1 ) )
            x( 2, axs( 1 ) )
            x( 2, axs( 1 ) )
            ];
        box( :, axs( 2 ) ) = [ ...
            x( 1, axs( 2 ) )
            x( 2, axs( 2 ) )
            x( 2, axs( 2 ) )
            x( 1, axs( 2 ) )
            ];
        box( :, ANALYSIS_DIMENSION ) = repmat( envelope.min_point( ANALYSIS_DIMENSION ), [ 4 1 ] );
        cc = zeros( [ 4 1 ] );
        ph = patch( patch_axh, box( :, 1 ), box( :, 2 ), box( :, 3 ), cc );
        ph.FaceColor = [ 0.3 0.3 0.3 ];
        ph.FaceAlpha = 0.5;
        ph.EdgeColor = [ 0 0 0 ];
        
        fh = figure();
        axh = axes( fh );
        imagesc( axh, flipud( rr.' ) );
        axis( axh, 'equal' );
    case 3
        volumeViewer( rr );
    otherwise
        assert( false )
end