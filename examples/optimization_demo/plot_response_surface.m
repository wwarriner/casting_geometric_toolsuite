function [ ...
    figure_handle, ...
    axes_handle, ...
    patch_handle ...
    ] = ...
    plot_response_surface( ...
    angles, ...
    interpolant, ...
    resolution, ...
    title, ...
    type ...
    )

if strcmpi( type, '3d' )
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
elseif strcmpi( type, '2d' )
    figure_handle = figure( ...
        'name', title, ...
        'color', 'w', ...
        'position', [ 0 0 2*resolution(1) resolution(2) ] ...
        );
    min_x = -pi;
    max_x = pi;
    min_y = -pi/2;
    max_y = pi/2;
    interp_resolution = 400;
    % x is 2*t+1, y is t+1, to ensure squares
    [ X, Y ] = meshgrid( ...
        linspace( min_x, max_x, 2 * interp_resolution + 1 ), ...
        linspace( min_y, max_y, interp_resolution + 1 )...
        );
    metric_results = interpolant( X, Y );
    X = rad2deg( X );
    Y = rad2deg( Y );
    subplot( 1, 2, 1 );
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
        'plabelmeridian', 0, ...
        'parallellabel', 'on', ...
        'fontcolor', 'w', ...
        'origin', newpole( 90, 0 )..., ...
        ...'maplonlimit', [ -90 90 ] ...
        );
    patch_handle = surfacem( Y, X, metric_results );
    uistack( patch_handle, 'bottom' );
    original_axes_size = axes_handle.Position;
    colorbar( axes_handle );
    axes_handle.Position = original_axes_size;
    colormap( axes_handle, plasma() );
    subplot( 1, 2, 2 );
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
        'origin', newpole( 90, 180 )..., ...
        ...'maplonlimit', [ 90 -90 ] ...
        );
    patch_handle = surfacem( Y, X, metric_results );
    uistack( patch_handle, 'bottom' );
    colormap( axes_handle, plasma() );
else
    assert( false );
end

end

