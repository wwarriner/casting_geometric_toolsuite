function plot_response_surface( ...
    interpolant, ...
    resolution, ...
    title, ...
    type ...
    )

if strcmpi( type, '3d' )
    plot_3d( title, interpolant, resolution )
elseif strcmpi( type, '2d' )
    plot_2d( title, interpolant, resolution )
else
    assert( false );
end

end


function plot_3d( title, interpolant, resolution )
    
    angles = generate_sphere_angles( 10000, 'octahedral' );
    figure_handle = figure( ...
        'name', title, ...
        'color', 'w', ...
        'position', [ 0 0 resolution ] ...
        );
    [ x, y, z ] = unitsph2cart( angles );
    tri = convhull( x, y, z );
    axes_handle = axes( figure_handle );
    metric_result = interpolant( angles( :, 1 ), angles( :, 2 ) );
    patch_handle = trisurf( ...
        tri, x, y, z, metric_result, ...
        'parent', axes_handle ...
        );
    patch_handle.FaceAlpha = 1;
    hold( axes_handle, 'on' );
    shading( axes_handle, 'interp' );
    colorbar( axes_handle );
    colormap( axes_handle, viridis() );
    box( axes_handle, 'on' );
    axis( axes_handle, 'vis3d' );

end


function plot_2d( title, interpolant, resolution )

    figure( ...
        'name', title, ...
        'color', 'w', ...
        'position', [ 0 0 2 * resolution( 1 ) resolution( 2 ) ] ...
        );
    
    MIN_X = -pi;
    MAX_X = pi;
    MIN_Y = -pi/2;
    MAX_Y = pi/2;    
    interp_resolution = 400;
    % x is 2*t+1, y is t+1, to ensure squares
    [ X, Y ] = meshgrid( ...
        linspace( MIN_X, MAX_X, 2 * interp_resolution + 1 ), ...
        linspace( MIN_Y, MAX_Y, interp_resolution + 1 )...
        );
    metric_results = interpolant( X, Y );
    X = rad2deg( X );
    Y = rad2deg( Y );
    
    subplot( 1, 2, 1 );
    axes_handle = prepare_axesm( newpole( 90, 0 ) );
    patch_handle = surfacem( Y, X, metric_results );
    uistack( patch_handle, 'bottom' );
    original_axes_size = axes_handle.Position;
    colorbar( axes_handle );
    axes_handle.Position = original_axes_size;
    
    subplot( 1, 2, 2 );
    prepare_axesm( newpole( 90, 180 ) );
    patch_handle = surfacem( Y, X, metric_results );
    uistack( patch_handle, 'bottom' );
    
end


function axes_handle = prepare_axesm( origin_newpole )

axes_handle = axesm( ...
    'breusing', ...
    'grid', 'on', ...
    'gcolor', 'w', ...
    'glinewidth', 1, ...
    'frame', 'on', ...
    'mlinelocation', 30, ...
    'mlabellocation', 30, ...
    'mlabelparallel', 15, ...
    'meridianlabel', 'on', ...
    'plinelocation', 30, ...
    'plabellocation', 30, ...
    'plabelmeridian', 180, ...
    'parallellabel', 'on', ...
    'fontcolor', 'w', ...
    'origin', origin_newpole...
    );
axis( axes_handle, 'off' );
colormap( axes_handle, plasma() );

end