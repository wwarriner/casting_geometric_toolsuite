%Plot the original STL mesh:
figure
fv = read_stl( "sample.stl" );
%fv = fix_vertex_ordering( fv );
patch( fv, "facecolor", "b" );
view( 3 );
axis( "equal", "vis3d" );

%Voxelise the STL:
min_p = min( fv.vertices );
max_p = max( fv.vertices );
grid = Grid( ...
    linspace(min_p(1),max_p(1),100), ...
    linspace(min_p(2),max_p(2),100), ...
    linspace(min_p(3),max_p(3),100) ...
    );
raster = Raster( grid, fv, "xyz" );
interior = raster.interior;

%Show the voxelised result:
fh = figure;
fh.Position = [ 50 50 1440 600 ];
subplot( 1, 3, 1 );
imagesc( squeeze( sum( interior, 1 ) ) );
color_map = gray( 256 );
colormap( color_map );
xlabel( "Z-direction" );
ylabel( "Y-direction" );
axis( "equal", "tight" );

subplot( 1, 3, 2 );
imagesc( squeeze( sum( interior, 2 ) ) );
colormap( color_map );
xlabel( "Z-direction" );
ylabel( "X-direction" );
axis( "equal", "tight" );

subplot( 1, 3, 3 );
imagesc( squeeze( sum( interior, 3 ) ) );
colormap( color_map );
xlabel( "Y-direction" );
ylabel( "X-direction" );
axis( "equal", "tight" );

% Show the normals as histograms.
normals = raster.normals;
fh = figure;
fh.Position = [ 60 40 1440 600 ];

subplot( 1, 3, 1 );
histogram( normals.x );
axis( "square", "tight" );

subplot( 1, 3, 2 );
histogram( normals.y );
axis( "square", "tight" );

subplot( 1, 3, 3 );
histogram( normals.z );
axis( "square", "tight" );

% Show the normals graphically.
f = zeros( grid.shape );
f( normals.indices ) = normals.x; % actually y in images
volumeViewer( f );


