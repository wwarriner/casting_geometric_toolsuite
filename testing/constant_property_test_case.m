%% DEFINITIONS
ambient_id = 0;
mold_id = 1;
melt_id = 2;
element_size_in_mm = 100; % mm
simulation_time_step_in_s = 100; % s

%% TEST MESH GENERATION
side_length = 50;
shape = [ ...
    side_length ...
    2 * side_length ...
    side_length / 2 ...
    ];
[ fdm_mesh, center ] = generate_test_mesh( mold_id, melt_id, shape );

%% TEST PROPERTY GENERATION
pp = generate_constant_test_properties( ambient_id, mold_id, melt_id );
pp.set_space_step( element_size_in_mm / 1000 ) % m
pp.set_max_length( shape ); % count
pp.prepare_for_solver();

%% MAIN LOOP SETUP
u_initial_nd = pp.generate_initial_temperature_field_nd( fdm_mesh );
u_prev_nd = u_initial_nd;
u_next_nd = u_initial_nd;

st = SolidificationTime( shape );

melt_fe_temp_nd = pp.get_feeding_effectivity_temperature_nd( melt_id );

mg = MatrixGenerator( fdm_mesh, ambient_id, @pp.lookup_rho_cp_nd, @pp.lookup_k_nd_half_space_step_inv, @pp.lookup_h_nd );

simulation_time_step_next_nd = pp.nondimensionalize_times( simulation_time_step_in_s );
simulation_time_growth_factor = .1;
simulation_time_nd = 0;
loop_count = 0;
computation_time = 0;

%% TEST PLOT SETUP
[ axhs, phs ] = test_plot_setup();

%% DRAW INITIAL TEMPERATURE FIELD
u_initial = pp.dimensionalize_temperatures( u_initial_nd );
draw_axial_plots_at_indices( axhs, shape, u_initial, center, 'k' );
drawnow();

%% DRAW FEEDING EFFECTIVITY TEMPERATURE
melt_fe_temp = pp.dimensionalize_temperatures( melt_fe_temp_nd );
draw_horizontal_lines( axhs, melt_fe_temp, 'k:' );
drawnow();

%% MAIN LOOP
finished = false;
while( ~finished )
    %% check stop condition
    if st.is_finished( fdm_mesh, melt_id )
        fprintf( 'fully solidified\n' );
        break;
    end
    
    %% generate coefficient matrix
    [ m_L, m_R, r_L, r_R ] = mg.generate( pp.get_ambient_temperature_nd(), pp.get_space_step_nd(), simulation_time_step_next_nd, u_prev_nd );
    times = mg.get_last_times();
    
    %% update simulation time
    simulation_time_nd = simulation_time_nd + simulation_time_step_next_nd;
    
    %% solve linear system
    tic;
    [ p, ~, ~, it ] = pcg( m_L, m_R * u_prev_nd( : ) + r_R - r_L, 1e-6, 100, [], [], u_prev_nd( : ) );
    times( end + 1 ) = toc;
    
    %% check energy integral here
    
    %% update results
    tic;
    u_next_nd = reshape( p, size( fdm_mesh ) );
    st.update_nd( fdm_mesh, melt_id, pp, u_prev_nd, u_next_nd, simulation_time_nd, simulation_time_step_next_nd );
    times( end + 1 ) = toc;
    
    %% update online plot
    delete( phs );
    u_next_d = pp.dimensionalize_temperatures( u_next_nd );
    phs = draw_axial_plots_at_indices( axhs, shape, u_next_d, center, 'r' );
    drawnow();
    
    %% update online information
    fprintf( '%.2f, ', times ); fprintf( '\n' );
    
    %% prepare for next iteration
    simulation_time_step_next_nd = ( 1 + simulation_time_growth_factor ) * simulation_time_step_next_nd;
    loop_count = loop_count + 1;
    u_prev_nd = u_next_nd;
    computation_time = computation_time + sum( times );
    
end

%% SUMMARIZE COMPUTATION
simulation_time = pp.dimensionalize_times( simulation_time_nd );
fprintf( 'time steps: %d\n', loop_count );
fprintf( 'computation time: %.2f\n', computation_time );
fprintf( 'simulation time: %.2f\n', simulation_time );
fprintf( 'biot/nusselt number: %.2f\n', side_length * element_size_in_mm / 1000 * 387 / 200 );
fprintf( 'bounary layer coefficient mold @ 10000s: %.2f\n', sqrt( pi * 50 / 7800 / 500 * 10000 ) );
fprintf( 'bounary layer coefficient melt @ 10000s: %.2f\n', sqrt( pi * 200 / 7800 / 900 * 10000 ) );

%% REDIMENSIONALIZE RESULTS
u_final = pp.dimensionalize_temperatures( u_next_nd );
st.manipulate( @pp.dimensionalize_times );

%% DRAW RESULTS
figure();
axhs( 1 ) = subplot( 3, 1, 1 );
axhs( 2 ) = subplot( 3, 1, 2 );
axhs( 3 ) = subplot( 3, 1, 3 );
draw_axial_plots_at_indices( axhs, shape, st.values, center, 'k' );

