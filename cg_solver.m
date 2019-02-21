%% SETUP
ambient_id = 0;
mold_id = 1;
melt_id = 2;
element_size_in_mm = 10; % mm

%% MESHING
k = 2;
side_length = 50;
%side_length = 4*k+1;
shape = [ side_length side_length side_length ];
mesh = mold_id * ones( shape );
center = floor( ( shape - 1 ) / 2 ) + 1;
quarter = floor( ( center - 1 ) / 2 );
melt_ranges = cellfun( ...
    @(x,y) ( x - y ) : ( x + y ), ...
    num2cell( center ), ...
    num2cell( quarter ), ...
    'uniformoutput', false ...
    );
mesh( melt_ranges{ 1 }, melt_ranges{ 2 }, melt_ranges{ 3 } ) = melt_id;

%% PROPERTIES
C_TO_K = 273.15;
ambient_ic = 25; % C
mold_ic = 25; % C
melt_ic = 700; % C
min_ic = min( mold_ic, melt_ic ); % K
max_ic = max( mold_ic, melt_ic ); % K
ambient_nd_ic = ( ambient_ic - min_ic ) / ( max_ic - min_ic );
mold_nd_ic = ( mold_ic - min_ic ) / ( max_ic - min_ic );
melt_nd_ic = ( melt_ic - min_ic ) / ( max_ic - min_ic );

melt_fs_val = [ 1.0 0.0 ];
melt_fs_temp = [ 659.9 660.1 ]; % K
melt_fs = MaterialProperty( melt_fs_temp, melt_fs_val );
melt_nd_fs = melt_fs.downscale( 1.0, max_ic, min_ic );
melt_fe = 0.5;

mold_k = MaterialProperty( 50 ); % W / m * K
melt_k = MaterialProperty( 200 ); % W / m * K
min_k = min( [ melt_k.values mold_k.values ] );
mold_nd_k = mold_k.downscale( min_k, max_ic, min_ic );
melt_nd_k = melt_k.downscale( min_k, max_ic, min_ic );
k_nds = [ mold_nd_k melt_nd_k ];
k_nd = @(x, u) k_nds( x ).lookup( u );

ambient_mold_h = MaterialProperty( 100 ); % W / m ^ 2 * K
ambient_melt_h = MaterialProperty( 100 ); % W / m ^ 2 * K
mold_melt_h = MaterialProperty( 387 ); % W / m ^ 2 * K
min_h = min( [ ambient_mold_h.values ambient_melt_h.values mold_melt_h.values ] );
ambient_mold_nd_h = ambient_mold_h.downscale( min_h, max_ic, min_ic );
ambient_melt_nd_h = ambient_mold_h.downscale( min_h, max_ic, min_ic );
mold_melt_nd_h = ambient_mold_h.downscale( min_h, max_ic, min_ic );
cc = Convection();
cc.add_convection( ambient_id, mold_id, ambient_mold_nd_h );
cc.add_convection( ambient_id, melt_id, ambient_melt_nd_h );
cc.add_convection( mold_id, melt_id, mold_melt_nd_h );
h_nd = @(x, y, u) cc.lookup( x, y, u );


space_step_in_m = element_size_in_mm / 1000; % m
max_L = space_step_in_m * max( shape( : ) );
space_step_nd = space_step_in_m / max_L;

mold_rho = MaterialProperty( 7800 ); % kg / m ^ 3
mold_cp = MaterialProperty( 500 ); % J / kg * K
melt_rho = MaterialProperty( 2700 ); % kg / m ^ 3
melt_cp = MaterialProperty( 900 ); % J / kg * K
rho_cp_melt = create_rho_cp( melt_rho, melt_cp, melt_k );
rho_cp_mold = create_rho_cp( mold_rho, mold_cp, mold_k );
max_rho_cp = max( [ rho_cp_melt.values rho_cp_mold.values ] );
rho_cp_nd_melt = rho_cp_melt.downscale( max_rho_cp, max_ic, min_ic );
rho_cp_nd_mold = rho_cp_mold.downscale( max_rho_cp, max_ic, min_ic );
rho_cp_nds = [ rho_cp_nd_mold rho_cp_nd_melt ];
rho_cp_nd = @(x, u) rho_cp_nds( x ).lookup( u );

time_step_in_s = 1;
min_transfer = min( [ min_k max_L * min_h ] );
time_step_factor = max_rho_cp / min_transfer * max_L ^ 2;
time_step_nd = time_step_in_s / time_step_factor;

u_init = ones( size( mesh ) );
u_init( mesh == mold_id ) = mold_nd_ic;
u_init( mesh == melt_id ) = melt_nd_ic;

%% solve
fh = figure();
axh1 = subplot( 3, 1, 1 );
hold( axh1, 'on' );
axh2 = subplot( 3, 1, 2 );
hold( axh2, 'on' );
axh3 = subplot( 3, 1, 3 );
hold( axh3, 'on' );
u_prev = u_init;
u_next = u_init;
plot( axh1, 1 : shape( 1 ), squeeze( u_init( :, center( 2 ), center( 3 ) ) ) * ( max_ic - min_ic ) + min_ic, 'k' );
plot( axh2, 1 : shape( 1 ), squeeze( u_init( center( 1 ), :, center( 3 ) ) ) * ( max_ic - min_ic ) + min_ic, 'k' );
plot( axh3, 1 : shape( 1 ), squeeze( u_init( center( 1 ), center( 2 ), : ) ) * ( max_ic - min_ic ) + min_ic, 'k' );
time_step_next = time_step_nd;
time_eps = .1;
time_count = 0;
time = 0;
computation_time = 0;

solidification_time = zeros( size( mesh ) );

melt_fe_temp = melt_fs.reverse_lookup( melt_fe );
melt_nd_fe_temp = melt_nd_fs.reverse_lookup( melt_fe );
plot( axh1, [ 1 shape( 1 ) ], [ melt_fe_temp melt_fe_temp ], 'k:' );
plot( axh2, [ 1 shape( 1 ) ], [ melt_fe_temp melt_fe_temp ], 'k:' );
plot( axh3, [ 1 shape( 1 ) ], [ melt_fe_temp melt_fe_temp ], 'k:' );
drawnow();
ph1 = [];
ph2 = [];
ph3 = [];

for i = 1 : 1000
    
    delete( ph1 );
    delete( ph2 );
    delete( ph3 );
    [ m_L, m_R ] = mg.generate( u_prev, space_step_nd, time_step_next );
    times = mg.get_last_times();
    tic;
    [ p, ~, ~, it ] = pcg( m_L, m_R * u_prev( : ), 1e-6, 100, [], [], u_prev( : ) );
    times( end + 1 ) = toc;
    tic;
    u_next = reshape( p, size( mesh ) );
    prev_time = time;
    time = time + time_step_next;
    fs_prev = melt_nd_fs.lookup( u_prev );
    fs_next = melt_nd_fs.lookup( u_next );
    sol_times = ( fs_next - melt_fe ) ./ ( fs_next - fs_prev ) .* ( time - prev_time ) + prev_time;
    updates = mesh == melt_id & fs_next > melt_fe & solidification_time == 0;
    solidification_time( updates ) = sol_times( updates );
    time_step_next = ( 1 + time_eps ) * time_step_next;
    time_count = time_count + 1;
    u_prev = u_next;
    times( end + 1 ) = toc;
    fprintf( '%.2f, ', times ); fprintf( '\n' );
    computation_time = computation_time + sum( times );
    hold( axh1, 'on' );
    ph1 = plot( axh1, 1 : shape( 1 ), squeeze( u_next( :, center( 2 ), center( 3 ) ) ) * ( max_ic - min_ic ) + min_ic, 'r' );
    hold( axh2, 'on' );
    ph2 = plot( axh2, 1 : shape( 1 ), squeeze( u_next( center( 1 ), :, center( 3 ) ) ) * ( max_ic - min_ic ) + min_ic, 'r' );
    hold( axh3, 'on' );
    ph3 = plot( axh3, 1 : shape( 1 ), squeeze( u_next( center( 1 ), center( 2 ), : ) ) * ( max_ic - min_ic ) + min_ic, 'r' );
    drawnow();
    if all( mesh ~= melt_id | solidification_time > 0 )
        fprintf( 'fully solidified\n' );
        break;
    end
    
end
fprintf( 'time steps: %d\n', time_count );
fprintf( 'computation time: %.2f\n', computation_time );

figure();
axh1 = subplot( 3, 1, 1 );
axh2 = subplot( 3, 1, 2 );
axh3 = subplot( 3, 1, 3 );
plot( axh1, 1 : shape( 1 ), squeeze( solidification_time( :, center( 2 ), center( 3 ) ) ) * time_step_factor );
plot( axh2, 1 : shape( 1 ), squeeze( solidification_time( center( 1 ), :, center( 3 ) ) ) * time_step_factor );
plot( axh3, 1 : shape( 1 ), squeeze( solidification_time( center( 1 ), center( 2 ), : ) ) * time_step_factor );
