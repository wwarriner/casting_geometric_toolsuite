classdef MatrixGenerator < handle
    
    methods ( Access = public )
        
        function obj = MatrixGenerator( fdm_mesh, ambient_id, q_fn, rho_fn, rho_cp_lookup_fn, k_half_space_step_inv_lookup_fn, h_lookup_fn )
            
            obj.ambient_id = ambient_id;
            obj.shape = size( fdm_mesh );
            obj.element_count = prod( obj.shape );
            obj.strides = [ 1 obj.shape( obj.X ) obj.shape( obj.X ) * obj.shape( obj.Y ) ];
            obj.fdm_mesh = fdm_mesh;
            obj.q_fn = q_fn;
            obj.rho_fn = rho_fn;
            obj.rho_cp_fn = rho_cp_lookup_fn;
            obj.k_half_space_step_inv_fn = k_half_space_step_inv_lookup_fn;
            obj.h_fn = h_lookup_fn;
            
        end
        
        
        function [ m_l, m_r, r_l, r_r ] = generate( obj, ambient_temperature, space_step, time_step, u_prev, u_next )
            
            obj.times = [];
            
            differential_element_factor = time_step / space_step;
            
            q_prev = obj.property_lookup( u_prev, obj.q_fn );
            q_next = obj.property_lookup( u_next, obj.q_fn );
            rho_prev = obj.property_lookup( u_prev, obj.rho_fn );
            rho_next = obj.property_lookup( u_next, obj.rho_fn );
            rho_cp = obj.property_lookup( u_next, obj.rho_cp_fn );
            
            TOL = 1e-6;
            d_u = u_next - u_prev;
            use_direct = abs( d_u ) < TOL;
            rho_cp( ~use_direct ) = mean( [ rho_next( ~use_direct ) rho_prev( ~use_direct ) ], 2 ) .* ...
                ( q_next( ~use_direct ) - q_prev( ~use_direct ) ) ./ d_u( ~use_direct );
            
            %rho_cp = obj.property_lookup( u, obj.rho_cp_fn );
            bc_indices = obj.determine_ambient_boundary_indices();
            
            ambient = obj.determine_ambient_diffusivity_vector( differential_element_factor, rho_cp, bc_indices, u_next );
            bands = obj.construct_bands( differential_element_factor, rho_cp, bc_indices, u_next );
            
            [ m_l, m_r ] = obj.construct_sparse( ambient, bands );
            [ r_l, r_r ] = obj.construct_ambient_bc_vectors( ambient_temperature, ambient );
            
        end
        
        
        function times = get_last_times( obj )
            
            times = obj.times;
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function values = property_lookup( obj, u, lookup_fn )
            
            tic;
            values = zeros( obj.element_count, 1 );
            ids = unique( obj.fdm_mesh );
            id_count = numel( ids );
            assert( id_count > 0 );
            for i = 1 : id_count
                
                id = ids( i );
                values( obj.fdm_mesh == id ) = lookup_fn( id, u( obj.fdm_mesh == id ) );
                
            end
            obj.times( end + 1 ) = toc;
            
        end
        
        
        function values = ambient_lookup( obj, u )
            
            values = zeros( obj.element_count, 1 );
            center_ids = obj.fdm_mesh( : );
            ids = unique( obj.fdm_mesh );
            id_count = numel( ids );
            assert( id_count > 0 );
            for i = 1 : id_count
                
                id = ids( i );
                values( center_ids == id ) = obj.h_fn( obj.ambient_id, id, u( center_ids == id ) );
                
            end
            
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
                    values( center_ids == first_id & neighbor_ids == second_id ) = obj.h_fn( first_id, second_id, u( center_ids == first_id & neighbor_ids == second_id ) );
                    values( center_ids == second_id & neighbor_ids == first_id ) = obj.h_fn( first_id, second_id, u( center_ids == second_id & neighbor_ids == first_id ) );
                    
                end
            end
            values = values( center_ids ~= neighbor_ids );
            
        end
        
        
        function bands = construct_bands( obj, differential_element_factor, rho_cp, bc_indices, u )
            
            tic;
            % construct bands regardless of bcs
            k_half_space_step_inv = obj.property_lookup( u, obj.k_half_space_step_inv_fn );
            mesh_ids = arrayfun( @(x)circshift( obj.fdm_mesh( : ), x ), [ obj.strides 0 ], 'uniformoutput', false );
            bands = cell2mat( arrayfun( @(x, y)obj.construct_band( rho_cp, k_half_space_step_inv, mesh_ids{ end }, x{ 1 }, y{ 1 }, u ), mesh_ids( 1 : end - 1 ), num2cell( obj.strides ), 'uniformoutput', false ) ) .* differential_element_factor;
            
            % nullify bands where bcs are
            for i = 1 : obj.DIM_COUNT
                
                bands( bc_indices{ i }, i ) = 0;
            
            end
            obj.times( end + 1 ) = toc;
            
        end
        
        
        function band = construct_band( obj, rho_cp, k_half_space_step_inv, center_ids, neighbor_ids, stride, u )
            
            band = zeros( size( rho_cp ) );
            % heat transfer
            band( neighbor_ids ~= center_ids ) = obj.convection_lookup( u, center_ids, neighbor_ids );
            k_half_space_step_inv_band = obj.k_half_space_step_inv_band( k_half_space_step_inv, stride );
            band( neighbor_ids == center_ids ) = k_half_space_step_inv_band( neighbor_ids == center_ids );
            % rho_cp
            band = band ./ mean( [ rho_cp circshift( rho_cp, stride ) ], 2 );
            
        end
        
        
        function [ m_l, m_r ] = construct_sparse( obj, ambient_diffusivity_sum, bands )
            
            tic;
            % this arrangement is 33% faster than bringing m_off into construction of m_r and m_l
            m_u = spdiags2( bands, obj.strides, obj.element_count, obj.element_count );
            diffs = obj.sum_diffusivities( bands ) + ambient_diffusivity_sum;
            m_r = spdiags2( 2 - diffs, 0, obj.element_count, obj.element_count ) + m_u + m_u.';
            m_l = spdiags2( 2 + diffs, 0, obj.element_count, obj.element_count ) - m_u - m_u.';
            obj.times( end + 1 ) = toc;
            
        end
        
        
        function vec = determine_ambient_diffusivity_vector( obj, differential_element_factor, rho_cp, bc_indices, u )
            
            h = obj.ambient_lookup( u );
            diffs = zeros( obj.element_count, obj.DIM_COUNT );
            for i = 1 : obj.DIM_COUNT
                
                ambient_rho_cp = obj.rho_cp_fn( obj.ambient_id, u( bc_indices{ i } ) );
                diffs( bc_indices{ i }, i ) = h( bc_indices{ i } ) ./ mean( [ rho_cp( bc_indices{ i } ) ambient_rho_cp ], 2 );
                
            end
            vec = obj.sum_diffusivities( diffs ) .* differential_element_factor;
            
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
            
            indices = cell( obj.DIM_COUNT, 1 );
            indices{ obj.X } = xn( : );
            indices{ obj.Y } = yn( : );
            indices{ obj.Z } = zn( : );
            
        end
        
        
        function diffs = sum_diffusivities( obj, bands )
            
            bands_alt = bands;
            for i = 1 : obj.DIM_COUNT
                
                bands_alt( :, i ) = circshift( bands_alt( :, i ), -obj.strides( i ) );
                
            end
            diffs = sum( [ bands bands_alt ], 2 );
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function [ r_l, r_r ] = construct_ambient_bc_vectors( ambient_temperature, ambient_diffusivity_sum )
            
            r_r = ambient_diffusivity_sum .* ambient_temperature;
            r_l = -r_r;
            
        end
        
        
        function band = k_half_space_step_inv_band( k_half_space_step_inv, stride )
            
            band = 1./ ( k_half_space_step_inv + circshift( k_half_space_step_inv, stride ) );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        ambient_id
        element_count
        shape
        strides
        fdm_mesh
        q_fn
        rho_fn
        rho_cp_fn
        k_half_space_step_inv_fn
        h_fn
        
        times
        
    end
    
    
    properties( Access = private, Constant )
        
        X = 1;
        Y = 2;
        Z = 3;
        DIM_COUNT = 3;
        
    end
    
end