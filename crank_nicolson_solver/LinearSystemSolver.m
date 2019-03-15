classdef LinearSystemSolver < handle
    
    properties ( Access = public, Constant )
        
        LOOKUP_TIME = 'lookup';
        BC_TIME = 'boundary';
        BAND_TIME = 'bands';
        DKDU_TIME = 'dkdu';
        KDDU_TIME = 'kddu sparse';
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
            obj.pcg_tol = 1e-3;
            obj.pcg_max_it = 100;
            obj.relaxation_parameter = 0.5;
            obj.latent_heat_target_fraction = 0.25;
            obj.quality_ratio_tolerance = 0.1;
            
            obj.times = containers.Map();
            obj.count = 0;
            obj.pcg_count = 0;
            
        end
        
        
        function set_implicitness_factor( obj, implicitness )
            
            assert( isscalar( implicitness ) );
            assert( isa( implicitness, 'double' ) );
            assert( 0 <= implicitness && implicitness <= 1 );
            
            obj.implicitness = implicitness;
            
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
        
        
        function set_adaptive_time_step_relaxation_parameter( obj, parameter )
            
            assert( isscalar( parameter ) );
            assert( isa( parameter, 'double' ) );
            assert( 0 <= parameter && parameter <= 1 );
            
            obj.relaxation_parameter = parameter;
            
        end
        
        
        function set_latent_heat_target_fraction( obj, fraction )
            
            assert( isscalar( fraction ) );
            assert( isa( fraction, 'double' ) );
            assert( 0 <= fraction && fraction <= 1 );
            
            obj.latent_heat_target_fraction = fraction;
            
        end
        
        
        function set_quality_ratio_tolerance( obj, tol )
            
            assert( isscalar( tol ) );
            assert( isa( tol, 'double' ) );
            assert( 0 < tol );
            
            obj.quality_ratio_tolerance = tol;
            
        end
        
        
        function [ u, q, time_step, dkdu ] = solve( ...
                obj, ...
                mesh, ...
                q_prev, ...
                u_prev, ...
                u_curr, ...
                time_step_prev ...
                )
            
            
            % precalculate bulk of effort
            [ m_diffusivities_nts, amb_diff_nts, dkdu_nts ] = obj.generate_diff_nts( ...
                obj.pp.get_space_step(), ...
                u_prev, ...
                u_curr ...
                );
            
            % reset
            solve_time = 0;
            check_time = 0;
            obj.count = 0;
            obj.pcg_count = 0;
            
            % BISECTION METHOD
            u_pcg_start = u_curr;
            best_qr = inf;
            TIME_STEP_INDEX = 2;
            time_step_range = [ 0 time_step_prev inf ];
            
            MAX_IT = 20;
            it = 0;
            TOL = 1e-2;
            time_step_change_ratio = inf;
            while it < MAX_IT && TOL < time_step_change_ratio
                
                it = it + 1;
                obj.count = obj.count + 1;
                
                tic;
                [ lhs, rhs, dkdu ] = obj.setup_system_of_equations_with_time_step( ...
                    time_step_range( TIME_STEP_INDEX ), ...
                    m_diffusivities_nts, ...
                    amb_diff_nts, ...
                    dkdu_nts, ...
                    u_curr ...
                    );
                [ u, pcg_it ] = obj.solve_system_of_equations( lhs, rhs, u_pcg_start );
                obj.pcg_count = obj.pcg_count + pcg_it;
                solve_time = solve_time + toc;
                
                tic;
                q = obj.pp.compute_melt_enthalpies( mesh, u );
                quality_ratio = obj.determine_solution_quality_ratio( q_prev, q );
                if abs( quality_ratio ) < best_qr
                    u_pcg_start = u;
                end
                
                check_time = check_time + toc;
                
                if obj.is_quality_ratio_sufficient( quality_ratio )
                    break;
                end
                [ time_step_range, time_step_change_ratio ] = obj.update_time_step_range( ...
                    quality_ratio, ...
                    time_step_range ...
                    );
                
            end
            time_step = time_step_range( TIME_STEP_INDEX );
            obj.times( obj.SOLVE_TIME ) = solve_time;
            obj.times( obj.CHECK_TIME ) = check_time;
            
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
            
            count = obj.count;
            
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
        count
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
        % nts - No Time Step
        % wts - With (multiplied by) Time Step
        % diff - diffusivity/ies
        %
        % rhs contains dkdu
        % third output arg is for record keeping only
        function [ ...
                lhs_wts, ...
                rhs_wts, ...
                dkdu_wts ...
                ] = setup_system_of_equations_with_time_step( ...
                obj, ...
                time_step, ...
                m_diff_nts, ...
                ambient_diff_nts, ...
                dkdu_nts, ...
                u_curr ...
                )
            
            ambient_diff_wts = ambient_diff_nts .* time_step;
            m_diff_wts = m_diff_nts .* time_step;
            [ lhs_wts, m_rhs_wts ] = obj.construct_kddu( ...
                m_diff_wts, ...
                ambient_diff_wts ...
                );
            [ bc_lhs_wts, bc_rhs_wts ] = ...
                obj.construct_ambient_bc_vectors( ambient_diff_wts );
            dkdu_wts = dkdu_nts .* time_step;
            rhs_wts = m_rhs_wts * u_curr( : ) + bc_rhs_wts - bc_lhs_wts + dkdu_wts;
            
        end
        
        
        function [ u, pcg_it ] = solve_system_of_equations( obj, lhs, rhs, start_point )
            
            preconditioner = ichol( lhs, struct( 'michol', 'on' ) );
            [ u, ~, ~, pcg_it, ~ ] = pcg( ...
                lhs, ...
                rhs, ...
                obj.pcg_tol, ...
                obj.pcg_max_it, ...
                preconditioner, ...
                preconditioner.', ...
                start_point( : ) ...
                );
            
        end
        
        
        function quality_ratio = determine_solution_quality_ratio( ...
                obj, ...
                q_prev, ...
                q ...
                )
            
            max_delta_q = max( q_prev( : ) - q( : ) );
            [ latent_heat, sensible_heat ] = obj.pp.get_min_latent_heat();
            desired_q = latent_heat * obj.latent_heat_target_fraction;
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
                    ( interval * obj.relaxation_parameter ) + time_step_range( LOWER_BOUND );
            else
                time_step_range( LOWER_BOUND ) = time_step_range( TIME_STEP );
                if isinf( time_step_range( UPPER_BOUND ) )
                    time_step_range( TIME_STEP ) = time_step_range( TIME_STEP ) / obj.relaxation_parameter;
                else
                    interval = range( time_step_range );
                    time_step_range( TIME_STEP ) = ...
                        ( interval * obj.relaxation_parameter ) + time_step_range( LOWER_BOUND );
                end
            end
            
            change_ratio = abs( old_time_step - time_step_range( TIME_STEP ) ) ./ old_time_step;
            
        end
        
        
        function [ m_diff_nts, ambient_diff_nts, dkdu_nts ] = generate_diff_nts( ...
                obj, ...
                space_step, ...
                u_prev, ...
                u_next ...
                )
            
            % compute differential element
            difference_element = 1 ./ space_step;
            
            % property lookup
            tic;
            rho = obj.property_lookup( Material.RHO, u_next );
            cp = obj.compute_cp( u_prev, u_next );
            k_inv = obj.property_lookup( Material.K_INV, u_next );
            % h is looked up only when we know both sides of every boundary
            obj.times( obj.LOOKUP_TIME ) = toc;
            
            % boundary condition residual vector construction
            tic;
            bc_indices = obj.determine_ambient_boundary_indices();
            ambient_diff_nts = obj.compute_ambient_diffusivities_no_time_step( ...
                difference_element, ...
                rho, ...
                cp, ...
                bc_indices, ...
                u_next ...
                );
            obj.times( obj.BC_TIME ) = toc;
            
            % matrix band/diagonal construction
            tic;
            [ ...
                diff_bands_nts, ...
                u_bands, ...
                rho_bands, ...
                cp_bands, ...
                k_bands, ...
                mesh_ids ...
                ] = obj.construct_bands_no_time_step( ...
                difference_element, ...
                u_next, ...
                rho, ...
                cp, ...
                k_inv, ...
                bc_indices ...
                );
            obj.times( obj.BAND_TIME ) = toc;
            
            % del k dot del u vector construction
            tic;
            dkdu_nts = obj.construct_dkdu_nts( ...
                difference_element, ...
                u_next, ...
                rho, ...
                cp, ...
                k_inv, ...
                u_bands, ...
                rho_bands, ...
                cp_bands, ...
                k_bands, ...
                bc_indices, ...
                mesh_ids ...
                );
            obj.times( obj.DKDU_TIME ) = toc;
            
            % k del^2 u sparse matrix construction
            tic;
            m_diff_nts = obj.construct_diffusivities_no_time_step( ...
                diff_bands_nts ...
                );
            obj.times( obj.KDDU_TIME ) = toc;
            
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
        
        
        function amb_diff_nts = compute_ambient_diffusivities_no_time_step( ...
                obj, ...
                d_element, ...
                rho, ...
                cp, ...
                bc_indices, ...
                u ...
                )
            
            amb_h = obj.ambient_convection_lookup( u );
            diffs = zeros( obj.element_count, obj.DIM_COUNT );
            for i = 1 : obj.DIM_COUNT
                
                amb_rho = obj.pp.lookup_ambient_values( Material.RHO, u( bc_indices{ i } ) );
                amb_cp = obj.pp.lookup_ambient_values( Material.CP, u( bc_indices{ i } ) );
                rho_cp = obj.compute_rho_cp( ...
                    rho( bc_indices{ i } ), amb_rho, ...
                    cp( bc_indices{ i } ), amb_cp ...
                    );
                diffs( bc_indices{ i }, i ) = amb_h( bc_indices{ i } ) ./ rho_cp;
                
            end
            amb_diff_nts = obj.sum_diffusivities( diffs ) .* d_element;
            
        end
        
        
        function values = ambient_convection_lookup( obj, u )
            
            values = zeros( obj.element_count, 1 );
            center_ids = obj.fdm_mesh( : );
            ids = unique( obj.fdm_mesh );
            id_count = numel( ids );
            assert( id_count > 0 );
            for i = 1 : id_count
                
                material_id = ids( i );
                values( center_ids == material_id ) = ...
                    obj.pp.lookup_ambient_h_values( material_id, u( center_ids == material_id ) );
                
            end
            
        end
        
        
        function [ ...
                diff_bands_nts, ...
                u_bands, ...
                rho_bands, ...
                cp_bands, ...
                k_bands, ...
                mesh_ids ...
                ] = construct_bands_no_time_step( ...
                obj, ...
                d_element, ...
                u, ...
                rho, ...
                cp, ...
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
            [ diff_bands_nts, u_bands, rho_bands, cp_bands, k_bands ] = cellfun( ...
                @(bc, n, s)obj.construct_band( u, rho, cp, k_inv, bc, mesh_ids{ end }, n, s ), ...
                bc_indices, ...
                mesh_ids( 1 : end - 1 ), ...
                num2cell( obj.strides ), ...
                'uniformoutput', false ...
                );
            diff_bands_nts = cell2mat( diff_bands_nts ) .* d_element;
            u_bands = cell2mat( u_bands );
            rho_bands = cell2mat( rho_bands );
            cp_bands = cell2mat( cp_bands );
            k_bands = cell2mat( k_bands );
            
        end
        
        
        function [ diff_band, u_band, rho_band, cp_band, k_band ] = construct_band( ...
                obj, ...
                u, ...
                rho, ...
                cp, ...
                k_inv, ...
                bc_indices, ...
                center_ids, ...
                neighbor_ids, ...
                stride ...
                )
            
            u_band = obj.compute_u_band( u, stride );
            rho_band = obj.compute_u_band( rho, stride );
            cp_band = obj.compute_u_band( cp, stride );
            rho_cp_band = obj.compute_rho_cp_band( rho, cp, stride );
            k_band = obj.compute_k_band( k_inv, center_ids, neighbor_ids, stride );
            h_band = obj.compute_h_band( u, u_band, center_ids, neighbor_ids );
            heat_transfer_band = nan( size( k_band ) );
            heat_transfer_band( center_ids == neighbor_ids ) = k_band( center_ids == neighbor_ids );
            heat_transfer_band( center_ids ~= neighbor_ids ) = h_band( center_ids ~= neighbor_ids );
            diff_band = heat_transfer_band ./ rho_cp_band;
            diff_band( bc_indices ) = 0;
            assert( ~any( isnan( heat_transfer_band ) ) );
            
        end
        
        
        function m_diffusivities_nts = construct_diffusivities_no_time_step( obj, diff_bands_nts )
            
            m_diffusivities_nts = spdiags2( ...
                diff_bands_nts, ...
                obj.strides, ...
                obj.element_count, ...
                obj.element_count ...
                );
            m_diffusivities_nts = m_diffusivities_nts + m_diffusivities_nts.';
            
        end
        
        
        function [ m_l, m_r ] = construct_kddu( obj, m_diffusivities_wts, ambient_diff_wts )
            
            diffusivities_wts = full( sum( m_diffusivities_wts, 2 ) ) + ambient_diff_wts;
            
            explicitness = 1 - obj.implicitness;
            m_r = spdiags2( ...
                2 - explicitness .* diffusivities_wts, ...
                0, ...
                obj.element_count, ...
                obj.element_count ...
                ) + ...
                explicitness .* m_diffusivities_wts;
            m_l = spdiags2( ...
                2 + obj.implicitness .* diffusivities_wts, ...
                0, ...
                obj.element_count, ...
                obj.element_count ...
                ) + ...
                obj.implicitness .* ( -m_diffusivities_wts );
            
        end
        
        
        function dkdu = construct_dkdu_nts( ...
                obj, ...
                d_element, ...
                u, ...
                rho_center, ...
                cp_center, ...
                k_inv, ...
                u_bands, ...
                rho_bands, ...
                cp_bands, ...
                k_bands, ...
                bc_indices, ...
                mesh_ids ...
                )
            
            % uses center difference where possible
            % uses forward/backward when opposite element is convective
            % uses 0 if both convective
            
            ec = obj.element_count;
            sx = obj.strides( obj.X );
            sy = obj.strides( obj.Y );
            sz = obj.strides( obj.Z );
            
            jumps = [ ...
                sy - sx, ...
                sz - sy, ...
                ec - sz ...
                ];
            
            k_center = 0.5 ./ k_inv;
            u_center = u( : );
            
            k_dkdu = zeros( size( k_bands ) );
            u_dkdu = zeros( size( u_bands ) );
            rho_cp_dkdu = zeros( size( u_bands ) );
            
            c = mesh_ids{ end };
            for i = 1 : obj.DIM_COUNT
                
                n_b = mesh_ids{ i };
                n_f = circshift( n_b, -2 .* obj.strides( i ) );
                
                k_b = k_bands( :, i );
                u_b = u_bands( :, i );
                rho_b = rho_bands( :, i );
                cp_b = cp_bands( :, i );
                
                k_f = circshift( k_b, -obj.strides( i ) );
                u_f = circshift( u_b, -2.*obj.strides( i ) );
                rho_f = circshift( rho_b, -2.*obj.strides( i ) );
                cp_f = circshift( cp_b, -2.*obj.strides( i ) );
                
                d_b = c ~= n_b;
                d_b( bc_indices{ i } ) = true;
                d_f = c ~= n_f;
                d_f( bc_indices{ i } + jumps( i ) ) = true;
                d_n = d_f & d_b;
                d_c = ~d_f & ~d_b;
                
                k_dkdu( ~d_f & d_b, i ) = k_f( ~d_f & d_b ) - k_center( ~d_f & d_b );
                k_dkdu( ~d_b & d_f, i ) = k_center( ~d_b & d_f ) - k_b( ~d_b & d_f );
                k_dkdu( d_n ) = 0;
                k_dkdu( d_c, i ) = ( k_f( d_c ) - k_b( d_c ) ) ./ 2;
                
                u_dkdu( ~d_f & d_b, i ) = u_f( ~d_f & d_b ) - u_center( ~d_f & d_b );
                u_dkdu( ~d_b & d_f, i ) = u_center( ~d_b & d_f ) - u_b( ~d_b & d_f );
                u_dkdu( d_n ) = 0;
                u_dkdu( d_c, i ) = ( u_f( d_c ) - u_b( d_c ) ) ./ 2;
                
                rho_cp_dkdu( ~d_f & d_b, i ) = obj.compute_rho_cp( ...
                    rho_b( ~d_f & d_b ), rho_center( ~d_f & d_b ), ...
                    cp_b( ~d_f & d_b ), cp_center( ~d_f & d_b ) ...
                    );
                rho_cp_dkdu( ~d_b & d_f, i ) = obj.compute_rho_cp( ...
                    rho_center( ~d_b & d_f ), rho_f( ~d_b & d_f ), ...
                    cp_center( ~d_b & d_f ), cp_f( ~d_b & d_f ) ...
                    );
                rho_cp_dkdu( d_n, i ) = ones( sum( d_n ), 1 );
                rho_cp_dkdu( d_c, i ) = obj.compute_rho_cp( ...
                    rho_b( d_c ), rho_f( d_c ), ...
                    cp_b( d_c ), cp_f( d_c ) ...
                    );
                
            end
            
            dkdu = sum( k_dkdu .* u_dkdu ./ rho_cp_dkdu, 2 ) .* d_element;
            assert( ~any( isnan( dkdu ) ) );
            
        end
        
        
        function h_band = compute_h_band( ...
                obj, ...
                u, ...
                u_band, ...
                center_ids, ...
                neighbor_ids ...
                )
            
            h_band = obj.convection_lookup( u, u_band, center_ids, neighbor_ids );
            h_band( center_ids == neighbor_ids ) = nan;
            
        end
        
        
        function values = convection_lookup( obj, u, u_band, center_ids, neighbor_ids )
            
            values = zeros( obj.element_count, 1 );
            ids = unique( obj.fdm_mesh );
            id_count = numel( ids );
            assert( id_count > 0 );
            mean_u = mean( [ u( : ) u_band ], 2 );
            for i = 1 : id_count
                for j = i + 1 : id_count
                    
                    first_id = ids( i );
                    second_id = ids( j );
                    values( center_ids == first_id & neighbor_ids == second_id ) = obj.pp.lookup_h_values( first_id, second_id, mean_u( center_ids == first_id & neighbor_ids == second_id ) );
                    values( center_ids == second_id & neighbor_ids == first_id ) = obj.pp.lookup_h_values( first_id, second_id, mean_u( center_ids == second_id & neighbor_ids == first_id ) );
                    
                end
            end
            
        end
        
        
        function diffs = sum_diffusivities( obj, bands )
            
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
        
        
        function [ bc_lhs_wts, bc_rhs_wts ] = construct_ambient_bc_vectors( ...
                obj, ...
                ambient_diffusivity_sum_wts ...
                )
            
            base_vector = ambient_diffusivity_sum_wts .* obj.pp.get_ambient_temperature();
            bc_lhs_wts = -obj.implicitness .* base_vector;
            bc_rhs_wts = ( 1 - obj.implicitness ) .* base_vector;
            
        end
        
        
        function sufficient = is_quality_ratio_sufficient( obj, quality_ratio )
            
            sufficient = abs( quality_ratio ) < obj.quality_ratio_tolerance;
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function rho_cp_band = compute_rho_cp_band( ...
                rho, ...
                cp, ...
                stride ...
                )
            
            rho_cp_band = LinearSystemSolver.compute_rho_cp( ...
                rho, circshift( rho, stride ), ...
                cp, circshift( cp, stride ) ...
                );
            
        end
        
        
        function rho_cp = compute_rho_cp( rho_lhs, rho_rhs, cp_lhs, cp_rhs )
            
            rho_cp_lhs = rho_lhs .* cp_lhs;
            rho_cp_rhs = rho_rhs .* cp_rhs;
            rho_cp = mean( [ rho_cp_lhs( : ) rho_cp_rhs( : ) ], 2 );
%             rho = mean( [ rho_lhs rho_rhs ], 2 );
%             cp = mean( [ cp_lhs cp_rhs ], 2 );
%             rho_cp = rho .* cp;
            
        end
        
        
        function k_band = compute_k_band( ...
                k_inv, ...
                center_ids, ...
                neighbor_ids, ...
                stride ...
                )
            
            k_band = 1./ ( k_inv + circshift( k_inv, stride ) );
            k_band( center_ids ~= neighbor_ids ) = nan;
            
        end
        
        
        function u_band = compute_u_band( u, stride )
            
            u_band = circshift( u( : ), stride );
            
        end
        
    end
    
end