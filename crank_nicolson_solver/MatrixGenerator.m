classdef MatrixGenerator < handle
    
    properties ( Access = public, Constant )
        
        LOOKUP_TIME = 1;
        BC_TIME = 2;
        BAND_TIME = 3;
        DKDU_TIME = 4;
        KDDU_TIME = 5;
        TIME_COUNT = 5;
        
    end
    
    
    methods ( Access = public )
        
        function obj = MatrixGenerator( fdm_mesh, physical_properties )
            
            obj.fdm_mesh = fdm_mesh;
            obj.shape = size( fdm_mesh );
            obj.element_count = prod( obj.shape );
            obj.strides = [ ...
                1 ...
                obj.shape( obj.X ) ...
                obj.shape( obj.X ) * obj.shape( obj.Y ) ...
                ];
            
            obj.pp = physical_properties;
            
            obj.times = [];
            
        end
        
        
        function [ m_l, m_r, r_l, r_r, dkdu ] = generate( ...
                obj, ...
                ambient_temperature, ...
                space_step, ...
                time_step, ...
                u_prev, ...
                u_next ...
                )
            % reset times
            obj.times = [];
            
            % compute differential element
            d_element = obj.compute_differential_element( space_step, time_step );
            
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
            ambient_diff = obj.compute_ambient_diffusivities( ...
                d_element, ...
                rho, ...
                cp, ...
                bc_indices, ...
                u_next ...
                );
            [ r_l, r_r ] = obj.construct_ambient_bc_vectors( ...
                ambient_temperature, ...
                ambient_diff ...
                );
            obj.times( obj.BC_TIME ) = toc;
            
            % matrix band/diagonal construction
            tic;
            [ diff_bands, u_bands, rho_bands, cp_bands, k_bands, mesh_ids ] = obj.construct_bands( ...
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
            dkdu = CKU;
            
            % k del^2 u sparse matrix construction
            tic;
            [ m_l, m_r ] = obj.construct_kddu( ambient_diff, diff_bands );
            obj.times( obj.KDDU_TIME ) = toc;
            
        end
        
        
        function times = get_last_times( obj )
            
            times = obj.times;
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function cp = compute_cp( obj, u_prev, u_next )
            
            % lookup cp and enthalpy
            
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
        
        
        function amb_diff = compute_ambient_diffusivities( ...
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
            amb_diff = obj.sum_diffusivities( diffs ) .* d_element;
            
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
        
        
        function [ diff_bands, u_bands, rho_bands, cp_bands, k_bands, mesh_ids ] = construct_bands( ...
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
            [ diff_bands, u_bands, rho_bands, cp_bands, k_bands ] = cellfun( ...
                @(bc, n, s)obj.construct_band( u, rho, cp, k_inv, bc, mesh_ids{ end }, n, s ), ...
                bc_indices, ...
                mesh_ids( 1 : end - 1 ), ...
                num2cell( obj.strides ), ...
                'uniformoutput', false ...
                );
            diff_bands = cell2mat( diff_bands ) .* d_element;
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
        
        
        function [ m_l, m_r ] = construct_kddu( obj, ambient_diff, diff_bands )
            
            % this arrangement is 33% faster than bringing m_u into construction of m_r and m_l
            m_u = spdiags2( diff_bands, obj.strides, obj.element_count, obj.element_count );
            diffs = obj.sum_diffusivities( diff_bands ) + ambient_diff;
            m_r = spdiags2( 2 - diffs, 0, obj.element_count, obj.element_count ) + m_u + m_u.';
            m_l = spdiags2( 2 + diffs, 0, obj.element_count, obj.element_count ) - m_u - m_u.';
            
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
        
    end
    
    
    methods ( Access = private, Static )
        
        function de = compute_differential_element( space_step, time_step )
            
            de = time_step / space_step;
            
        end
        
        
        function [ r_l, r_r ] = construct_ambient_bc_vectors( ambient_temperature, ambient_diffusivity_sum )
            
            r_r = ambient_diffusivity_sum .* ambient_temperature;
            r_l = -r_r;
            
        end
        
        
        function rho_cp_band = compute_rho_cp_band( ...
                rho, ...
                cp, ...
                stride ...
                )
            
            rho_cp_band = MatrixGenerator.compute_rho_cp( ...
                MatrixGenerator.mean_property( rho, circshift( rho, stride ) ), ...
                MatrixGenerator.mean_property( cp, circshift( cp, stride ) ) ...
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
    
    
    properties ( Access = private )
        
        fdm_mesh
        element_count
        shape
        strides
        
        pp
        
        times
        
    end
    
    
    properties( Access = private, Constant )
        
        X = 1;
        Y = 2;
        Z = 3;
        DIM_COUNT = 3;
        
    end
    
end