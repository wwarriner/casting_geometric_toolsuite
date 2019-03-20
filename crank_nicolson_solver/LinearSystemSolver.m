classdef LinearSystemSolver < handle
    
    properties ( Access = public, Constant )
        
        LOOKUP_TIME = 'lookup';
        BC_TIME = 'boundary';
        BAND_TIME = 'bands';
        DKDU_TIME = 'dkdu';
        KDDU_TIME = 'kddu sparse';
        SETUP_TIME = 'set up linear system';
        SOLVE_TIME = 'linear solver';
        CHECK_TIME = 'quality check';
        
    end
    
    
    methods ( Access = public )
        
        function obj = LinearSystemSolver( fdm_mesh, physical_properties )
            
            obj.fdm_mesh = fdm_mesh;
            obj.shape = size( fdm_mesh );
            obj.element_count = prod( obj.shape );
            obj.strides = [ ...
                1 ...
                obj.shape( obj.X ) ...
                obj.shape( obj.X ) * obj.shape( obj.Y ) ...
                ];
            
            obj.pp = physical_properties;
            
            % DEFAULTS
            obj.implicitness = 1.0;
            obj.pcg_tol = 1e-4;
            obj.pcg_max_it = 100;
            obj.latent_heat_target_fraction = 0.25;
            obj.quality_ratio_tolerance = 0.1;
            
            obj.times = containers.Map();
            
        end
        
        
        function set_implicitness( obj, implicitness )
            
            assert( isscalar( implicitness ) );
            assert( isa( implicitness, 'double' ) );
            assert( 0 <= implicitness && implicitness <= 1 );
            
            obj.implicitness = implicitness;
            
        end
        
        
        function value = get_implicitness( obj )
            
            value = obj.implicitness;
            
        end
        
        
        function value = get_explicitness( obj )
            
            value = 1 - obj.implicitness;
            
        end
        
        
        function set_solver_tolerance( obj, tol )
            
            assert( isscalar( tol ) );
            assert( isa( tol, 'double' ) );
            assert( 0 < tol );
            
            obj.pcg_tol = tol;
            
        end
        
        
        function set_solver_max_iteration_count( obj, iteration_count )
            
            assert( isscalar( iteration_count ) );
            assert( isa( iteration_count, 'double' ) );
            assert( 0 < iteration_count );
            
            obj.pcg_max_it = iteration_count;
            
        end
        
        
        function set_latent_heat_target_fraction( obj, fraction )
            
            assert( isscalar( fraction ) );
            assert( isa( fraction, 'double' ) );
            assert( 0 <= fraction );
            
            obj.latent_heat_target_fraction = fraction;
            
        end
        
        
        function set_quality_ratio_tolerance( obj, tol )
            
            assert( isscalar( tol ) );
            assert( isa( tol, 'double' ) );
            assert( 0 < tol );
            
            obj.quality_ratio_tolerance = tol;
            
        end
        
        
        function [ u, q, time_step, dkdu_term ] = solve( ...
                obj, ...
                mesh, ...
                q_prev, ...
                u_prev, ...
                u_curr, ...
                time_step_prev ...
                )
            
            q_prev = q_prev( : );
            u_prev = u_prev( : );
            u_curr = u_curr( : );
            
            dx = obj.pp.get_space_step();
            
            % PRE TIME STEP
            
            % look up properties
            tic;
            rho_cp = obj.property_lookup( Material.RHO, u_curr ) .* ...
                obj.compute_cp( u_prev, u_curr );
            k = obj.property_lookup( Material.K, u_curr );
            % h is looked up only when we know both sides of every boundary
            
            % determines bands by circshifting
            
            obj.times( obj.LOOKUP_TIME ) = toc;
            
            % compute boundary resistances
            tic;
            boundary_indices = obj.determine_ambient_boundary_indices();
            boundary_heat_flow = obj.compute_boundary_heat_flow( ...
                dx, ...
                u_curr, ...
                k, ...
                boundary_indices ...
                );
            obj.times( obj.BC_TIME ) = toc;
            
            % construct internal heat flow matrix
            tic;
            internal_resistance_bands = zeros( obj.element_count, obj.DIM_COUNT );
            for i = 1 : obj.DIM_COUNT
                
                internal_resistance_bands( :, i ) = ...
                    obj.compute_resistance_band( dx, u_curr, k, obj.strides( i ) );
                internal_resistance_bands( boundary_indices{ i }, i ) = 0;
                
            end
            obj.times( obj.BAND_TIME ) = toc;
            tic; 
            m_internal_heat_flow = obj.construct_internal_heat_flow_matrix( dx, internal_resistance_bands );
            obj.times( obj.KDDU_TIME ) = toc;
            
            % construct dkdu term
            % TODO MAKE OPTIONAL
            tic;
            dkdu_term = obj.construct_dkdu_term( ...
                dx, ...
                u_curr, ...
                k, ...
                boundary_indices ...
                );
            obj.times( obj.DKDU_TIME ) = toc;
            
            % DETERMINE TIME STEP
            % uses bisection method
            
            % setup
            setup_time = 0;
            solve_time = 0;
            check_time = 0;
            solver_it = 1;
            pcg_it = 0;
            
            best_u = u_curr;
            best_quality_ratio = inf;
            TIME_STEP_INDEX = 2;
            time_step_range = [ 0 time_step_prev inf ];
            
            MAX_IT = 20; % refactor to client parameter
            TIME_STEP_CHANGE_TOL = 1e-2; % refactor to client parameter
            time_step_change_ratio = inf;
            % refactor loop condition
            while solver_it <= MAX_IT && ...
                    TIME_STEP_CHANGE_TOL < time_step_change_ratio 
                
                % set up linear system
                tic;
                [ lhs, rhs ] = obj.setup_linear_system( ...
                    time_step_range( TIME_STEP_INDEX ), ...
                    rho_cp, ...
                    m_internal_heat_flow, ...
                    boundary_heat_flow, ...
                    dkdu_term, ...
                    u_curr ...
                    );
                setup_time = setup_time + toc;
                
                % solve linear system
                tic;
                [ u, pcg_it_curr ] = obj.solve_system_of_equations( lhs, rhs, best_u );
                pcg_it = pcg_it + pcg_it_curr;
                solve_time = solve_time + toc;
                
                % check solution
                tic;
                q = obj.pp.compute_melt_enthalpies( mesh, u ); % todo refactor mesh
                quality_ratio = obj.determine_solution_quality_ratio( q_prev, q );
                if abs( quality_ratio ) < best_quality_ratio
                    best_u = u;
                end
                check_time = check_time + toc;
                
                % preferred end condition
                if obj.is_quality_ratio_sufficient( quality_ratio )
                    break;
                end
                [ time_step_range, time_step_change_ratio ] = obj.update_time_step_range( ...
                    quality_ratio, ...
                    time_step_range ...
                    );
                
                % update loop
                solver_it = solver_it + 1;
                
            end
            
            % store computation times
            time_step = time_step_range( TIME_STEP_INDEX );
            obj.times( obj.SETUP_TIME ) = setup_time;
            obj.times( obj.SOLVE_TIME ) = solve_time;
            obj.times( obj.CHECK_TIME ) = check_time;
            obj.solver_count = solver_it;
            obj.pcg_count = pcg_it;
            
        end
        
        
        function labels = get_time_labels( obj )
            
            labels = obj.times.keys();
            
        end
        
        
        function time = get_last_total_time( obj )
            
            time = sum( obj.get_last_times() );
            
        end
        
        
        function times = get_last_times( obj )
            
            times = cell2mat( obj.times.values() );
            
        end
        
        
        function times = get_last_times_map( obj )
            
            times = obj.times;
            
        end
        
        
        function count = get_last_solver_count( obj )
            
            count = obj.solver_count;
            
        end
        
        
        function count = get_last_pcg_count( obj )
            
            count = obj.pcg_count;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        fdm_mesh
        element_count
        shape
        strides
        
        pp
        
        implicitness
        pcg_tol
        pcg_max_it
        relaxation_parameter
        latent_heat_target_fraction
        quality_ratio_tolerance
        
        times
        solver_count
        pcg_count
        
    end
    
    
    properties( Access = private, Constant )
        
        X = 1;
        Y = 2;
        Z = 3;
        DIM_COUNT = 3;
        
    end
    
    
    methods ( Access = private )
        
        % lhs - Left Hand Side of linear system
        % rhs - Right Hand Side
        % amb - ambient, i.e. global boundary
        % diff - diffusivity/ies
        %
        % rhs contains dkdu
        % third output arg is for record keeping only
        function [ lhs, rhs ] = setup_linear_system( ...
                obj, ...
                dt, ...
                rho_cp, ...
                m_heat_flow, ...
                boundary_heat_flow, ...
                dkdu_term, ...
                u ...
                )
            
            % apply time step
            m_flow = dt .* m_heat_flow;
            boundary_flow = dt .* boundary_heat_flow;
            
            % precompute sum of resistances for main diagonal
            flow_sum = full( sum( m_flow, 2 ) ) + boundary_flow;
            
            % left-hand side
            lhs = spdiags2( ...
                rho_cp + ( obj.get_implicitness() .* flow_sum ), ...
                0, ...
                obj.element_count, ...
                obj.element_count ...
                ) + ...
                obj.get_implicitness() .* ( -m_flow );
            
            % right-hand side
            % refactor in case of 0 explicitness, don't need a sparse matrix
            m_rhs = spdiags2( ...
                rho_cp - ( obj.get_explicitness() .* flow_sum ), ...
                0, ...
                obj.element_count, ...
                obj.element_count ...
                ) + ...
                obj.get_explicitness() .* m_flow;
            [ v_b_lhs, v_b_rhs ] = obj.construct_boundary_heat_flow_vectors( ...
                boundary_heat_flow ...
                );
            rhs = m_rhs * u + v_b_rhs - v_b_lhs;% + dkdu_term; % refactor optional dkdu term inside this function?
            
        end
        
        
        function [ u, pcg_it ] = solve_system_of_equations( ...
                obj, ...
                lhs, ...
                rhs, ...
                u_guess ...
                )
            
            preconditioner = ichol( lhs, struct( 'michol', 'on' ) );
            [ u, ~, ~, pcg_it, ~ ] = pcg( ...
                lhs, ...
                rhs, ...
                obj.pcg_tol, ...
                obj.pcg_max_it, ...
                preconditioner, ...
                preconditioner.', ...
                u_guess( : ) ...
                );
            
        end
        
        
        function quality_ratio = determine_solution_quality_ratio( ...
                obj, ...
                q_prev, ...
                q ...
                )
            
            max_delta_q = max( q_prev( : ) - q( : ) );
            [ latent_heat, sensible_heat ] = obj.pp.get_min_latent_heat();
            % if latent heat very small, use sensible heat over freezing range instead
            heat = max( latent_heat, sensible_heat );
            desired_q = heat * obj.latent_heat_target_fraction;
            quality_ratio = ( max_delta_q - desired_q ) / desired_q;
            
        end
        
        
        function [ time_step_range, change_ratio ] = update_time_step_range( ...
                obj, ...
                quality_ratio, ...
                time_step_range ...
                )
            
            LOWER_BOUND = 1;
            TIME_STEP = 2;
            UPPER_BOUND = 3;
            
            old_time_step = time_step_range( TIME_STEP );
            
            % todo find way to choose relaxation parameter based on gradient?
            if 0 < quality_ratio
                time_step_range( UPPER_BOUND ) = time_step_range( TIME_STEP );
                interval = range( time_step_range );
                time_step_range( TIME_STEP ) = ...
                    ( interval * 0.5 ) + time_step_range( LOWER_BOUND );
            else
                time_step_range( LOWER_BOUND ) = time_step_range( TIME_STEP );
                if isinf( time_step_range( UPPER_BOUND ) )
                    time_step_range( TIME_STEP ) = time_step_range( TIME_STEP ) / 0.5;
                else
                    interval = range( time_step_range );
                    time_step_range( TIME_STEP ) = ...
                        ( interval * 0.5 ) + time_step_range( LOWER_BOUND );
                end
            end
            
            change_ratio = abs( old_time_step - time_step_range( TIME_STEP ) ) ./ old_time_step;
            
        end
        
        
        function cp = compute_cp( obj, u_prev, u_next )
            
            % direct calculation of cp
            cp_direct = mean( [ ...
                obj.property_lookup( Material.CP, u_prev ) ...
                obj.property_lookup( Material.CP, u_next ) ...
                ], 2 );
            
            % secant calculation for matrix regularization
            d_u = u_next( : ) - u_prev( : );
            cp = ( ...
                obj.property_lookup( Material.Q, u_next ) - ...
                obj.property_lookup( Material.Q, u_prev ) ...
                ) ./ d_u;
            
            % selection
            TOL = 1e-6;
            use_direct = abs( d_u ) < TOL;
            cp( use_direct ) = cp_direct( use_direct );
            
        end
        
        
        function indices = determine_ambient_boundary_indices( obj )
            
            ec = obj.element_count;
            sx = obj.strides( obj.X );
            sy = obj.strides( obj.Y );
            sz = obj.strides( obj.Z );
            
            bases = { ...
                ( 1 : sx : sy ) ...
                ( 1 : sy : sz ) ...
                ( 1 : sz : ec ) ...
                };
            
            xn = bases{ obj.Y }.' + bases{ obj.Z } - 1;
            yn = bases{ obj.X }.' + bases{ obj.Z } - 1;
            zn = bases{ obj.X }.' + bases{ obj.Y } - 1;
            
            indices = cell( 1, obj.DIM_COUNT );
            indices{ obj.X } = xn( : );
            indices{ obj.Y } = yn( : );
            indices{ obj.Z } = zn( : );
            
        end
        
        
        function resistances = compute_boundary_heat_flow( ...
                obj, ...
                space_step, ...
                u, ...
                k, ...
                boundary_indices ...
                )
            
            h = obj.boundary_convection_lookup( u );
            resistances = zeros( obj.element_count, obj.DIM_COUNT );
            for i = 1 : obj.DIM_COUNT
                
                resistances( boundary_indices{ i }, i ) = ...
                    space_step ./ k( boundary_indices{ i } ) ...
                    + 1 ./ h( boundary_indices{ i } );
                
            end
            resistances = sum( resistances, 2 );
            
        end
        
        
        function values = boundary_convection_lookup( obj, u )
            
            values = zeros( obj.element_count, 1 );
            center_ids = obj.fdm_mesh( : );
            ids = unique( obj.fdm_mesh ); % todo pull out
            id_count = numel( ids );
            for i = 1 : id_count
                
                material_id = ids( i );
                values( center_ids == material_id ) = ...
                    obj.pp.lookup_ambient_h_values( material_id, u( center_ids == material_id ) );
                
            end
            
        end
        
        
        function [ ...
                heat_transfer_bands, ...
                u_bands, ...
                k_bands, ...
                mesh_ids ...
                ] = construct_bands( ...
                obj, ...
                d_element, ...
                u, ...
                k_inv, ...
                bc_indices ...
                )
            
            % mesh_ids{ end } is center_ids
            % mesh_ids{ x } is stride( x ) diagonal ids
            mesh_ids = arrayfun( ...
                @(x)circshift( obj.fdm_mesh( : ), x ), ...
                [ obj.strides 0 ], ...
                'uniformoutput', false ...
                );
            [ heat_transfer_bands, u_bands, k_bands ] = cellfun( ...
                @(bc, n, s)obj.construct_band( u, k_inv, bc, mesh_ids{ end }, n, s ), ...
                bc_indices, ...
                mesh_ids( 1 : end - 1 ), ...
                num2cell( obj.strides ), ...
                'uniformoutput', false ...
                );
            heat_transfer_bands = cell2mat( heat_transfer_bands ) .* d_element;
            u_bands = cell2mat( u_bands );
            k_bands = cell2mat( k_bands );
            
        end
        
        
        function [ heat_transfer_band, u_band, k_band ] = construct_band( ...
                obj, ...
                u, ...
                k_inv, ...
                bc_indices, ...
                center_ids, ...
                neighbor_ids, ...
                stride ...
                )
            
            u_band = obj.compute_u_band( u, stride );
            k_band = obj.compute_k_band( k_inv, center_ids, neighbor_ids, stride );
            h_band = obj.compute_h_band( u, k_inv, center_ids, neighbor_ids, stride );
            
            heat_transfer_band = nan( size( k_band ) );
            heat_transfer_band( center_ids == neighbor_ids ) = k_band( center_ids == neighbor_ids );
            heat_transfer_band( center_ids ~= neighbor_ids ) = h_band( center_ids ~= neighbor_ids );
            heat_transfer_band( bc_indices ) = 0;
            
            assert( ~any( isnan( heat_transfer_band ) ) );
            
        end
        
        
        function m_heat_flow = construct_internal_heat_flow_matrix( ...
                obj, ...
                dx, ...
                resistance_bands ...
                )
            
            heat_flow_bands = 1 ./ ( dx .* resistance_bands );
            heat_flow_bands( ~isfinite( heat_flow_bands ) ) = 0;
            m_heat_flow = spdiags2( ...
                heat_flow_bands, ...
                obj.strides, ...
                obj.element_count, ...
                obj.element_count ...
                );
            m_heat_flow = m_heat_flow + m_heat_flow.';
            
        end
        
        
        function [ m_l, m_r ] = construct_kddu( obj, rho_cp, space_step, time_step, m_heat_transfer, amb_heat_transfer )
            
            m_heat_transfer = m_heat_transfer .* time_step;
            amb_heat_transfer = amb_heat_transfer .* time_step;
            heat_transfer_sum = full( sum( m_heat_transfer, 2 ) ) + amb_heat_transfer;
            
            explicitness = 1 - obj.implicitness;
            m_r = spdiags2( ...
                rho_cp - explicitness .* heat_transfer_sum, ...
                0, ...
                obj.element_count, ...
                obj.element_count ...
                ) + ...
                explicitness .* m_heat_transfer;
            m_l = spdiags2( ...
                rho_cp + obj.implicitness .* heat_transfer_sum, ...
                0, ...
                obj.element_count, ...
                obj.element_count ...
                ) + ...
                obj.implicitness .* ( -m_heat_transfer );
            
        end
        
        
        function dkdu_term = construct_dkdu_term( ...
                obj, ...
                dx, ...
                u_c, ...
                k_c, ...
                boundary_indices ...
                )
            
            % uses center difference where possible
            % uses forward/backward when opposite element is convective
            % uses 0 if both convective
            % prefixes:
            %  n is neighbor_mesh_ids
            %  k, u, rho, cp have the same meaning as elsewhere
            %  d is numerical difference (back, fwd, center)
            % suffixes:
            %  b is backward difference
            %  f is forward difference
            %  c is center difference
            %  n is no difference
            
            % factor out
            ec = obj.element_count;
            sx = obj.strides( obj.X );
            sy = obj.strides( obj.Y );
            sz = obj.strides( obj.Z );
            jumps = [ ...
                sy - sx, ...
                sz - sy, ...
                ec - sz ...
                ];
            
            k_dkdu = zeros( obj.element_count, 1 );
            u_dkdu = zeros( obj.element_count, 1 );
            for i = 1 : obj.DIM_COUNT
                
                d_b = false( obj.element_count, 1 );
                d_b( boundary_indices{ i } ) = true;
                
                d_f = false( obj.element_count, 1 );
                d_f( boundary_indices{ i } + jumps( i ) ) = true;
                
                d_n = d_f & d_b;
                d_c = ~d_f & ~d_b;
                
                k_b = circshift( k_c, obj.strides( i ) );
                k_f = circshift( k_c, -obj.strides( i ) );
                k_dkdu( ~d_f & d_b, i ) = k_f( ~d_f & d_b ) - k_c( ~d_f & d_b );
                k_dkdu( ~d_b & d_f, i ) = k_c( ~d_b & d_f ) - k_b( ~d_b & d_f );
                k_dkdu( d_n ) = 0;
                k_dkdu( d_c, i ) = ( k_f( d_c ) - k_b( d_c ) ) ./ 2;
                
                u_b = circshift( u_c, obj.strides( i ) ); % todo repeated
                u_f = circshift( u_c, -obj.strides( i ) );
                u_dkdu( ~d_f & d_b, i ) = u_f( ~d_f & d_b ) - u_c( ~d_f & d_b );
                u_dkdu( ~d_b & d_f, i ) = u_c( ~d_b & d_f ) - u_b( ~d_b & d_f );
                u_dkdu( d_n ) = 0;
                u_dkdu( d_c, i ) = ( u_f( d_c ) - u_b( d_c ) ) ./ 2;
                
            end
            dkdu_term = sum( k_dkdu .* u_dkdu, 2 ) ./ ( dx * dx );
            
        end
        
        
        % prefixes:
        %  - u: temperature
        %  - k: thermal conductivity
        %  - dx: space step
        % suffixes:
        %  - c: center (main diagonal)
        %  - n: neighbors (off diagonal)
        function r_c = compute_resistance_band( obj, dx, u_c, k_c, stride )
            
            u_n = circshift( u_c, stride );
            k_n = circshift( k_c, stride );
            r_c = ...
                dx ./ ( 2 .* k_c ) + ... % todo repeated calculation dx/2
                dx ./ ( 2 .* k_n );
            
            ids_c = obj.fdm_mesh( : );
            ids_n = circshift( ids_c, stride );
            h_c = obj.convection_lookup( u_c, u_n, ids_c, ids_n );
            r_c( ids_c ~= ids_n ) = ...
                r_c( ids_c ~= ids_n ) + ...
                1 ./ h_c( ids_c ~= ids_n );
            
        end
        
        
        function h_c = convection_lookup( obj, u_c, u_n, ids_c, ids_n )
            
            % todo merge with ambient somehow
            h_c = zeros( obj.element_count, 1 );
            ids = unique( obj.fdm_mesh ); % todo pull out
            id_count = numel( ids );
            mean_u = mean( [ u_c( : ) u_n ], 2 ); % todo repeated calculation mean
            for i = 1 : id_count
                for j = i + 1 : id_count
                    
                    first = ids( i );
                    second = ids( j );
                    h_c( ids_c == first & ids_n == second ) = obj.pp.lookup_h_values( first, second, mean_u( ids_c == first & ids_n == second ) );
                    h_c( ids_c == second & ids_n == first ) = obj.pp.lookup_h_values( first, second, mean_u( ids_c == second & ids_n == first ) );
                    
                end
            end
            %values = values ./ 2;
            
        end
        
        
        function diffs = sum_heat_transfer( obj, bands )
            
            bands_alt = bands;
            for i = 1 : obj.DIM_COUNT
                
                bands_alt( :, i ) = circshift( bands_alt( :, i ), -obj.strides( i ) );
                
            end
            diffs = sum( [ bands bands_alt ], 2 );
            
        end
        
        
        function values = property_lookup( obj, property_id, u )
            
            values = zeros( obj.element_count, 1 );
            mesh_ids = unique( obj.fdm_mesh );
            id_count = numel( mesh_ids );
            assert( id_count > 0 );
            for i = 1 : id_count
                
                material_id = mesh_ids( i );
                values( obj.fdm_mesh == material_id ) = ...
                    obj.pp.lookup_values( material_id, property_id, u( obj.fdm_mesh == material_id ) );
                
            end
            
        end
        
        
        function [ lhs, rhs ] = construct_boundary_heat_flow_vectors( ...
                obj, ...
                boundary_heat_flow ...
                )
            
            base = obj.pp.get_ambient_temperature() .* boundary_heat_flow;
            base( ~isfinite( base ) ) = 0;
            lhs = obj.get_implicitness() .* ( -base );
            rhs = obj.get_explicitness() .* base;
            
        end
        
        
        function sufficient = is_quality_ratio_sufficient( obj, quality_ratio )
            
            sufficient = abs( quality_ratio ) < obj.quality_ratio_tolerance;
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function rho_cp_band = compute_rho_cp_band( ...
                rho, ...
                cp ...
                )
            
            rho_cp_band = rho .* cp;
            
        end
        
        
        function rho_cp = compute_rho_cp( rho_lhs, rho_rhs, cp_lhs, cp_rhs )
            
            rho_cp_lhs = rho_lhs .* cp_lhs;
            rho_cp_rhs = rho_rhs .* cp_rhs;
            rho_cp = mean( [ rho_cp_lhs( : ) rho_cp_rhs( : ) ], 2 );
            %             rho = mean( [ rho_lhs rho_rhs ], 2 );
            %             cp = mean( [ cp_lhs cp_rhs ], 2 );
            %             rho_cp = rho .* cp;
            
        end
        
        
        function k_band = compute_resistance_bands( u, k, stride )
            
            k_band = 1./ ( k_inv + circshift( k_inv, stride ) );
            k_band( center_ids ~= neighbor_ids ) = nan;
            
        end
        
        
        function u_band = compute_u_band( u, stride )
            
            u_band = circshift( u( : ), stride );
            
        end
        
    end
    
end