classdef SolidificationProblem < modeler.super.Problem
    
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
        
        function obj = SolidificationProblem( ...
                fdm_mesh, ...
                physical_properties, ...
                linear_system_solver ...
                )
            
            assert( isa( linear_system_solver, 'modeler.LinearSystemSolver' ) );
            
            obj.fdm_mesh = fdm_mesh;
            obj.shape = size( fdm_mesh );
            obj.element_count = prod( obj.shape );
            obj.strides = [ ...
                1 ...
                obj.shape( obj.X ) ...
                obj.shape( obj.X ) * obj.shape( obj.Y ) ...
                ];
            
            obj.pp = physical_properties;
            
            obj.linear_system_solver = linear_system_solver;
            
            obj.u_previous = obj.pp.generate_initial_temperature_field( obj.fdm_mesh );
            obj.u = obj.pp.generate_initial_temperature_field( obj.fdm_mesh );
            obj.u_candidate = obj.pp.generate_initial_temperature_field( obj.fdm_mesh );
            obj.q = obj.pp.compute_melt_enthalpies( obj.fdm_mesh, obj.u );
            obj.q_candidate = obj.pp.compute_melt_enthalpies( obj.fdm_mesh, obj.u_candidate );
            
            obj.finish_temperature = obj.pp.get_solidus_temperature();
            
            % DEFAULTS
            obj.implicitness = 1.0;
            obj.latent_heat_target_ratio = 0.25;
            
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
        
        
        function set_latent_heat_target_ratio( obj, ratio )
            
            assert( isscalar( ratio ) );
            assert( isa( ratio, 'double' ) );
            assert( 0 < ratio );
            
            obj.latent_heat_target_ratio = ratio;
            
        end
        
        
        function set_finish_temperature( obj, temperature )
            
            obj.finish_temperature = temperature;
            
        end
        
        
        function prepare( obj )
            
            obj.u_previous = obj.u;
            obj.u = obj.u_candidate;
            obj.q = obj.q_candidate;
            obj.rho_cp = obj.compute_rho_cp( obj.u_previous( : ), obj.u( : ) );
            [ obj.boundary_heat_flow, obj.internal_heat_flow ] = ...
                obj.compute_heat_flow( obj.u( : ) );
            
        end
        
        
        function quality = solve( obj, time_step )
            
            % set up linear system
            tic;
            [ lhs, rhs ] = obj.setup_linear_system( ...
                time_step, ...
                obj.rho_cp, ...
                obj.internal_heat_flow, ...
                obj.boundary_heat_flow, ...
                obj.u( : ) ...
                );
            obj.times( obj.SETUP_TIME ) = toc;
            
            % solve linear system
            obj.u_candidate = obj.linear_system_solver.solve( lhs, rhs, obj.u( : ) );
            obj.u_candidate = reshape( obj.u_candidate, size( obj.u ) );
            obj.pcg_count = obj.linear_system_solver.get_iteration_count();
            obj.times( obj.SOLVE_TIME ) = obj.linear_system_solver.get_time();
            
            % check solution
            tic;
            [ quality, obj.q_candidate ] = ...
                obj.determine_solution_quality( obj.q, obj.u_candidate );
            obj.times( obj.CHECK_TIME ) = toc;
            
        end
        
        
        function finished = is_finished( obj )
            
            finished = all( obj.u < obj.finish_temperature, 'all' );
            
        end
        
        
        function u = get_temperature( obj )
            
            u = obj.u_candidate;
            
        end
        
        
        function u = get_previous_temperature( obj )
            
            u = obj.u;
            
        end
        
        
        function q = get_enthalpy( obj )
            
            q = obj.q_candidate;
            
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
        
        
        function count = get_solver_count( obj )
            
            count = obj.pcg_count;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        fdm_mesh
        element_count
        shape
        strides
        
        pp
        
        linear_system_solver
        
        rho_cp
        boundary_heat_flow
        internal_heat_flow
        
        u
        u_previous
        u_candidate
        q
        q_previous
        q_candidate
        
        finish_temperature
        
        times
        pcg_count
        
        implicitness
        latent_heat_target_ratio
        
    end
    
    
    properties( Access = private, Constant )
        
        X = 1;
        Y = 2;
        Z = 3;
        DIM_COUNT = 3;
        
    end
    
    
    methods ( Access = private )
        
        function rho_cp = compute_rho_cp( obj, u_prev, u_curr )
            
            rho_cp = obj.property_lookup( Material.RHO, u_curr ) .* ...
                obj.compute_cp( u_prev, u_curr ); % TODO refactor precompute
            
        end
        
        
        function [ boundary, internal ] = compute_heat_flow( obj, u_curr )
            
            k = obj.property_lookup( Material.K, u_curr );
            [ boundary, indices ] = obj.compute_boundary_heat_flow( u_curr, k );
            internal = obj.compute_internal_heat_flow( u_curr, k, indices );
            % dkdu = obj.compute_dkdu_term( u_curr, k, indices );
            
        end
        
        
        function [ heat_flow, boundary_indices ] = compute_boundary_heat_flow( obj, u_curr, k )
            
            tic;
            
            dx = obj.pp.get_space_step();
            boundary_indices = obj.determine_ambient_boundary_indices();
            resistances = obj.compute_boundary_resistances( ...
                dx, ...
                u_curr, ...
                k, ...
                boundary_indices ...
                );
            heat_flow = 1 ./ resistances;
            heat_flow( ~isfinite( heat_flow ) ) = 0;
            
            obj.times( obj.BC_TIME ) = toc;
            
        end
        
        
        function m_heat_flow = compute_internal_heat_flow( obj, u_curr, k, boundary_indices )
            
            tic;
            
            dx = obj.pp.get_space_step();
            resistance_bands = zeros( obj.element_count, obj.DIM_COUNT );
            for i = 1 : obj.DIM_COUNT
                
                resistance_bands( :, i ) = ...
                    obj.compute_resistance_band( dx, u_curr, k, obj.strides( i ) );
                resistance_bands( boundary_indices{ i }, i ) = 0;
                
            end
            
            obj.times( obj.BAND_TIME ) = toc;
            
            tic;
            
            heat_flow_bands = 1 ./ resistance_bands;
            m_heat_flow = obj.construct_internal_heat_flow_matrix( heat_flow_bands );
            
            obj.times( obj.KDDU_TIME ) = toc;
            
        end
        
        
        function dkdu = compute_dkdu_term( obj, u_curr, k, boundary_indices )
            
            tic;
            
            dx = obj.pp.get_space_step();
            dkdu = obj.construct_dkdu_term( ...
                dx, ...
                u_curr, ...
                k, ...
                boundary_indices ...
                );
            
            obj.times( obj.DKDU_TIME ) = toc;
            
        end
        
        
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
                u ..., ...
                ...dkdu_term ...
                )
            
            % apply time step
            dx = obj.pp.get_space_step();
            m_flow = dt .* m_heat_flow ./ dx;
            boundary_flow = dt .* sum( boundary_heat_flow, 2 ) ./ dx;
            
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
            % DIDNT SAVE TIME??
            m_rhs = spdiags2( ...
                rho_cp - ( obj.get_explicitness() .* flow_sum ), ...
                0, ...
                obj.element_count, ...
                obj.element_count ...
                ) + ...
                obj.get_explicitness() .* m_flow;
            [ v_b_lhs, v_b_rhs ] = obj.construct_boundary_heat_flow_vectors( ...
                boundary_flow ...
                );
            rhs = m_rhs * u + v_b_rhs - v_b_lhs;% + dkdu_term; % refactor optional dkdu term inside this function?
            
        end
        
        
        function [ quality, q ] = determine_solution_quality( ...
                obj, ...
                q_prev, ...
                u ...
                )
            
            q = obj.pp.compute_melt_enthalpies( obj.fdm_mesh( : ), u ); % todo refactor mesh
            max_delta_q = max( q_prev( : ) - q( : ) );
            [ latent_heat, sensible_heat ] = obj.pp.get_min_latent_heat();
            % if latent heat very small, use sensible heat over freezing range instead
            heat = max( latent_heat, sensible_heat );
            desired_q = heat * obj.latent_heat_target_ratio;
            quality = ( max_delta_q - desired_q ) / desired_q;
            
        end
        
        
        function cp = compute_cp( obj, u_prev, u_next )
            
            % refactor into cp class
            % direct calculation of cp
            cp_direct = obj.property_lookup( Material.CP, u_next );
            
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
        
        
        function resistances = compute_boundary_resistances( ...
                obj, ...
                dx, ...
                u, ...
                k, ...
                boundary_indices ...
                )
            
            h = obj.boundary_convection_lookup( u );
            resistances = zeros( obj.element_count, obj.DIM_COUNT );
            for i = 1 : obj.DIM_COUNT
                
                resistances( boundary_indices{ i }, i ) = ...
                    dx ./ ( 2 * k( boundary_indices{ i } ) ) ...
                    + 1 ./ h( boundary_indices{ i } );
                
            end
            
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
        
        
        function m_heat_flow = construct_internal_heat_flow_matrix( ...
                obj, ...
                heat_flow_bands ...
                )
            
            heat_flow_bands( ~isfinite( heat_flow_bands ) ) = 0;
            m_heat_flow = spdiags2( ...
                heat_flow_bands, ...
                obj.strides, ...
                obj.element_count, ...
                obj.element_count ...
                );
            m_heat_flow = m_heat_flow + m_heat_flow.';
            
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
                dx ./ ( 3 .* k_c ) + ... % todo repeated calculation dx/2
                dx ./ ( 3 .* k_n );
            
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
        
    end
    
end