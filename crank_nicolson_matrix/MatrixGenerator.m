classdef MatrixGenerator < handle
    
    methods ( Access = public )
        
        function obj = MatrixGenerator( fdm_mesh, rho_cp_lookup_fn, k_half_space_step_inv_lookup_fn, h_lookup_fn )
            
            obj.shape = size( fdm_mesh );
            obj.element_count = prod( obj.shape );
            obj.strides = [ 1 obj.shape( 1 ) obj.shape( 1 ) * obj.shape( 2 ) ];
            obj.strips = [ -obj.strides obj.strides ];
            obj.off_band_count = numel( obj.strips );
            obj.fdm_mesh = fdm_mesh;
            obj.rho_cp_fn = rho_cp_lookup_fn;
            obj.k_half_space_step_inv_fn = k_half_space_step_inv_lookup_fn;
            obj.h_fn = h_lookup_fn;
            
        end
        
        
        function [ m_l, m_r ] = generate( obj, u, space_step, time_step )
            
            obj.times = [];
            alpha_factor = time_step / space_step;
            bands = obj.construct_bands( u, alpha_factor );
            [ m_l, m_r ] = obj.construct_sparse( bands );
            
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
        
        
        function values = convection_lookup( obj, u, center_ids, neighbor_ids, lookup_fn )
            
            tic;
            values = zeros( obj.element_count, 1 );
            ids = unique( obj.fdm_mesh );
            id_count = numel( ids );
            assert( id_count > 0 );
            for i = 1 : id_count
                for j = i + 1 : id_count
                    
                    first_id = ids( i );
                    second_id = ids( j );
                    values( center_ids == first_id & neighbor_ids == second_id ) = lookup_fn( first_id, second_id, u( center_ids == first_id & neighbor_ids == second_id ) );
                    values( center_ids == second_id & neighbor_ids == first_id ) = lookup_fn( first_id, second_id, u( center_ids == second_id & neighbor_ids == first_id ) );
                    
                end
            end
            values = values( center_ids ~= neighbor_ids );
            
        end
        
        
        function bands = construct_bands( obj, u, alpha_factor )
            
            tic;
            
            mesh_ids = arrayfun( @(x)circshift( obj.fdm_mesh( : ), x ), [ obj.strips 0 ], 'uniformoutput', false );
            rho_cp = obj.property_lookup( u, obj.rho_cp_fn );
            k_half_space_step_inv = obj.property_lookup( u, obj.k_half_space_step_inv_fn );
            bands = cell2mat( arrayfun( @(x, y)obj.construct_band( u, rho_cp, k_half_space_step_inv, mesh_ids{ end }, x{ 1 }, y{ 1 } ), mesh_ids( 1 : end - 1 ), num2cell( obj.strips ), 'uniformoutput', false ) );
            bands = bands .* alpha_factor;
            obj.times( end + 1 ) = toc;
            
        end
        
        
        function band = construct_band( obj, u, rho_cp, k_half_space_step_inv, center_ids, neighbor_ids, stride )
            
            band = zeros( size( rho_cp ) );
            % heat transfer
            band( neighbor_ids ~= center_ids ) = 1 ./ obj.convection_lookup( u, center_ids, neighbor_ids, obj.h_fn );
            k_half_space_step_inv_band = obj.k_half_space_step_inv_band( k_half_space_step_inv, stride );
            band( neighbor_ids == center_ids ) = k_half_space_step_inv_band( neighbor_ids == center_ids );
            % rho_cp
            band = 1 ./ ( band .* mean( [ rho_cp circshift( rho_cp, stride ) ], 2 ) );
            
        end
        
        
        function [ m_l, m_r ] = construct_sparse( obj, bands )
            
            tic;
            % this arrangement is 33% faster than bringing m_off into construction of m_r and m_l
            m_off = spdiags2( bands, obj.strips, obj.element_count, obj.element_count );
            m_r = spdiags2( 2 - sum( bands, 2 ), 0, obj.element_count, obj.element_count ) + m_off;
            m_l = spdiags2( 2 + sum( bands, 2 ), 0, obj.element_count, obj.element_count ) - m_off;
            obj.times( end + 1 ) = toc;
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function band = k_half_space_step_inv_band( k_half_space_step_inv, stride )
            
            band = k_half_space_step_inv + circshift( k_half_space_step_inv, stride );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        element_count
        shape
        strides
        strips
        off_band_count
        fdm_mesh
        rho_cp_fn
        k_half_space_step_inv_fn
        h_fn
        
        times
        
    end
    
end