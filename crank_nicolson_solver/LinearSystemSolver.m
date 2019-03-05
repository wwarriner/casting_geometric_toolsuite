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
            
            % default fully implicit
            obj.implicitness = 1.0;
            obj.pcg_tol = 1e-6;
            obj.pcg_max_it = 100;
            obj.relaxation_parameter = 0.5;
            obj.latent_heat_target_fraction = 0.5;
            obj.quality_ratio_tolerance = 0.01;
            
            obj.times = containers.Map();
            
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
        
        
        function [ u_nd, q_nd, step_nd, dkdu ] = solve( ...
                obj, ...
                mesh, ...
                q_prev_nd, ...
                u_prev_nd, ...
                u_curr_nd, ...
                prev_step_nd ...
                )
            
            initial_time_steps = [ ...
                obj.relaxation_parameter ...
                1 ...
                2 - obj.relaxation_parameter ...
                ] .* prev_step_nd;
            
            % precalculate bulk of effort
            [ m_diffusivities_nts, amb_diff_nts, dkdu_nts ] = obj.generate_no_time_step( ...
                obj.pp.get_space_step_nd(), ...
                u_prev_nd, ...
                u_curr_nd ...
                );
            
            time_steps = [];
            quality_ratios = [];
            
            solve_time = 0;
            check_time = 0;
            obj.count = 0;
            %fh = figure();
            %axh = axes( fh );
            %hold( axh, 'on' );
            % SECANT METHOD
            while true
                
                obj.count = obj.count + 1;
                
                if numel( time_steps ) < 3
                    next_step = initial_time_steps( 1 );
                    initial_time_steps( 1 ) = [];
                else
                    next_step = time_steps( 1 ) - quality_ratios( 1 ) * ...
                        ( time_steps( 1 ) - time_steps( 2 ) ) ./ ( quality_ratios( 1 ) - quality_ratios( 2 ) );
                end
                next_step = max( next_step, 0 );
                time_steps = [ next_step time_steps ];
                
                tic;
                [ lhs, rhs, dkdu ] = obj.setup_system_of_equations_with_time_step( ...
                    time_steps( 1 ), ...
                    m_diffusivities_nts, ...
                    amb_diff_nts, ...
                    dkdu_nts, ...
                    u_curr_nd ...
                    );
                u_nd = obj.solve_system_of_equations( lhs, rhs, u_curr_nd );
                solve_time = solve_time + toc;

                tic;
                q_nd = obj.pp.compute_melt_enthalpies_nd( mesh, u_nd );
                quality_ratios = [ obj.determine_solution_quality_ratio( q_prev_nd, q_nd ) quality_ratios ];
                
                %plot( axh, time_steps( 1 ), quality_ratios( 1 ), 'marker', '.', 'linestyle', 'none' );
                drawnow();
                check_time = check_time + toc;
                
                if obj.is_quality_ratio_sufficient( quality_ratios( 1 ) )
                    step_nd = time_steps( 1 );
                    break;
                end
                
            end
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
        
    end
    
    
    properties( Access = private, Constant )
        
        X = 1;
        Y = 2;
        Z = 3;
        DIM_COUNT = 3;
        
    end
    
    
    methods ( Access = private )
        
        function [ ...
                lhs_wts, ...
                rhs_wts, ...
                dkdu_wts ...
                ] = setup_system_of_equations_with_time_step( ...
                obj, ...
                time_step, ...
                m_diffusivities_nts, ...
                amb_diff_nts, ...
                dkdu_nts, ...
                u_curr_nd ...
                )
            
            amb_diff_wts = amb_diff_nts .* time_step;
            [ lhs_wts, m_r_wts ] = obj.construct_kddu( ...
                m_diffusivities_nts, ...
                amb_diff_wts, ...
                time_step ...
                );
            [ bc_lhs_wts, bc_rhs_wts ] = ...
                obj.construct_ambient_bc_vectors( amb_diff_wts );
            dkdu_wts = dkdu_nts .* time_step;
            rhs_wts = m_r_wts * u_curr_nd( : ) + bc_rhs_wts - bc_lhs_wts + dkdu_wts;
            
        end
        
        
        function u_nd = solve_system_of_equations( obj, lhs, rhs, start_point )
            
            [ u_nd, ~, ~, ~, ~ ] = pcg( ...
                lhs, ...
                rhs, ...
                obj.pcg_tol, ...
                obj.pcg_max_it, ...
                [], ...
                [], ...
                start_point( : ) ...
                );
            
        end
        
        
        function quality_ratio = determine_solution_quality_ratio( ...
                obj, ...
                q_prev_nd, ...
                q_nd ...
                )
            
            max_delta_q_nd = max( q_prev_nd( : ) - q_nd( : ) );
            [ latent_heat_nd, sensible_heat_nd ] = obj.pp.get_min_latent_heat_nd();
            desired_q_nd = ( latent_heat_nd + sensible_heat_nd ) * obj.latent_heat_target_fraction;
            quality_ratio = ( max_delta_q_nd - desired_q_nd ) / desired_q_nd;
            
        end
        
        
        function time_step_range = choose_next_time_step_range( ...
                obj, ...
                quality_ratio, ...
                time_step_range ...
                )
            
            LOWER_BOUND = 1;
            TIME_STEP = 2;
            UPPER_BOUND = 3;
            
            % todo find way to choose relaxation parameter based on gradient?
            if 0 < quality_ratio
                time_step_range( UPPER_BOUND ) = time_step_range( TIME_STEP );
                interval = range( time_step_range );
                time_step_range( TIME_STEP ) = ( interval * obj.relaxation_parameter ) + time_step_range( 1 );
            else
                time_step_range( LOWER_BOUND ) = time_step_range( TIME_STEP );
                time_step_range( TIME_STEP ) = time_step_range( TIME_STEP ) / obj.relaxation_parameter;
            end
            
        end
        
        
        function [ m_diffusivities_nts, ambient_diff_nts, dkdu_nts ] = generate_no_time_step( ...
                obj, ...
                space_step, ...
                u_prev, ...
                u_next ...
                )
            
            % compute differential element
            d_element = 1 ./ space_step;
            
            % property lookup
            tic;
            rho = obj.property_lookup( obj.pp.RHO_INDEX, u_next );
            cp = obj.compute_cp( u_prev, u_next );
            k_inv = obj.property_lookup( obj.pp.K_INV_INDEX, u_next );
            % h is looked up only when we know both sides of every boundary
            obj.times( obj.LOOKUP_TIME ) = toc;
            
            % boundary condition residual vector construction
            tic;
            bc_indices = obj.determine_ambient_boundary_indices();
            ambient_diff_nts = obj.compute_ambient_diffusivities_no_time_step( ...
                d_element, ...
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
                d_element, ...
                u_next, ...
                rho, ...
                cp, ...
                k_inv, ...
                bc_indices ...
                );
            obj.times( obj.BAND_TIME ) = toc;
            
            % del k dot del u vector construction
            tic;
            [ CKU, UKU ] = obj.construct_dkdu( ...
                d_element, ...
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
            dkdu_nts = CKU;
            
            % k del^2 u sparse matrix construction
            tic;
            m_diffusivities_nts = obj.construct_diffusivities_no_time_step( ...
                diff_bands_nts ...
                );
            obj.times( obj.KDDU_TIME ) = toc;
            
        end
        
        
        function cp = compute_cp( obj, u_prev, u_next )
            
            % direct calculation of cp
            cp_direct = mean( [ ...
                obj.property_lookup( obj.pp.CP_INDEX, u_prev ) ...
                obj.property_lookup( obj.pp.CP_INDEX, u_next ) ...
                ], 2 );
            
            % secant calculation for matrix regularization
            d_u = u_next( : ) - u_prev( : );
            cp = ( ...
                obj.property_lookup( obj.pp.Q_INDEX, u_next ) - ...
                obj.property_lookup( obj.pp.Q_INDEX, u_prev ) ...
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
                
                amb_rho = obj.pp.lookup_ambient_values( obj.pp.RHO_INDEX, u( bc_indices{ i } ) );
                amb_cp = obj.pp.lookup_ambient_values( obj.pp.CP_INDEX, u( bc_indices{ i } ) );
                rho_cp = obj.compute_rho_cp( ...
                    obj.mean_property( rho( bc_indices{ i } ), amb_rho ), ...
                    obj.mean_property( cp( bc_indices{ i } ), amb_cp ) ...
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
            h_band = obj.compute_h_band( u, center_ids, neighbor_ids );
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
        
        
        function [ m_l, m_r ] = construct_kddu( obj, m_diffusivities_nts, ambient_diff_wts, time_step )
            
            m_diffusivities_wts = m_diffusivities_nts .* time_step;
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
        
        
        function [ CKU, UKU ] = construct_dkdu( ...
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
                    obj.mean_property( rho_b( ~d_f & d_b ), rho_center( ~d_f & d_b ) ), ...
                    obj.mean_property( cp_b( ~d_f & d_b ), cp_center( ~d_f & d_b ) ) ...
                    );
                rho_cp_dkdu( ~d_b & d_f, i ) = obj.compute_rho_cp( ...
                    obj.mean_property( rho_center( ~d_b & d_f ), rho_f( ~d_b & d_f ) ), ...
                    obj.mean_property( cp_center( ~d_b & d_f ), cp_f( ~d_b & d_f ) ) ...
                    );
                rho_cp_dkdu( d_n, i ) = obj.compute_rho_cp( rho_center( d_n ), cp_center( d_n ) );
                rho_cp_dkdu( d_c, i ) = obj.compute_rho_cp( ...
                    obj.mean_property( rho_b( d_c ), rho_f( d_c ) ), ...
                    obj.mean_property( cp_b( d_c ), cp_f( d_c ) ) ...
                    );
                
            end
            
            CKU = sum( k_dkdu .* u_dkdu ./ rho_cp_dkdu, 2 ) .* d_element;
            assert( ~any( isnan( CKU ) ) );
            UKU = [];
            %
            %             fd_k = k_bands - k_center;
            %             bd_k = k_center - k_bands_b;
            %             fd_u = u_bands - u_center;
            %             bd_u = u_center - u_bands_b;
            %             upwind_k = max( fd_k, 0 ) + min( bd_k, 0 );
            %             upwind_u = max( fd_u, 0 ) + min( bd_u, 0 );
            %             k_u( c_inds ) = upwind_k( c_inds );
            %             u_u( c_inds ) = upwind_u( c_inds );
            %             UKU = sum( k_u .* u_u ./ rho_cp_bands, 2 ) .* d_element;
            
        end
        
        
        function h_band = compute_h_band( ...
                obj, ...
                u, ...
                center_ids, ...
                neighbor_ids ...
                )
            
            h_band = obj.convection_lookup( u, center_ids, neighbor_ids );
            h_band( center_ids == neighbor_ids ) = nan;
            
        end
        
        
        function values = convection_lookup( obj, u, center_ids, neighbor_ids )
            
            values = zeros( obj.element_count, 1 );
            ids = unique( obj.fdm_mesh );
            id_count = numel( ids );
            assert( id_count > 0 );
            for i = 1 : id_count
                for j = i + 1 : id_count
                    
                    first_id = ids( i );
                    second_id = ids( j );
                    values( center_ids == first_id & neighbor_ids == second_id ) = obj.pp.lookup_h_values( first_id, second_id, u( center_ids == first_id & neighbor_ids == second_id ) );
                    values( center_ids == second_id & neighbor_ids == first_id ) = obj.pp.lookup_h_values( first_id, second_id, u( center_ids == second_id & neighbor_ids == first_id ) );
                    
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
            
            bc_rhs_wts = ambient_diffusivity_sum_wts .* obj.pp.get_ambient_temperature_nd();
            bc_lhs_wts = -bc_rhs_wts;
            
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
                LinearSystemSolver.mean_property( rho, circshift( rho, stride ) ), ...
                LinearSystemSolver.mean_property( cp, circshift( cp, stride ) ) ...
                );
            
        end
        
        
        function rho_cp = compute_rho_cp( rho, cp )
            
            rho_cp = rho .* cp;
            
        end
        
        
        function prop = mean_property( prop_lhs, prop_rhs )
            
            prop = mean( [ prop_lhs( : ) prop_rhs( : ) ], 2 );
            
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