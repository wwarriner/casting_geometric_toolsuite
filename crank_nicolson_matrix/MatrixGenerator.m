classdef MatrixGenerator < handle
    
    methods ( Access = public )
        
        function obj = MatrixGenerator( fdm_mesh, rho_cp_lookup_fn, k_lookup_fn )
            
            obj.shape = size( fdm_mesh );
            obj.element_count = prod( obj.shape );
            obj.strides = [ 1 obj.shape( 1 ) obj.shape( 1 ) * obj.shape( 2 ) ];
            obj.strips = [ -obj.strides obj.strides ];
            obj.fdm_mesh = fdm_mesh;
            obj.rho_cp_fn = rho_cp_lookup_fn;
            obj.k_fn = k_lookup_fn;
            
        end
        
        
        function [ m_l, m_r ] = generate( obj, u, space_step, time_step )
            
            obj.times = [];
            alpha_factor = time_step / ( space_step ^ 2 );
            rho_cp = obj.property_lookup( u, obj.rho_cp_fn );
            k = obj.property_lookup( u, obj.k_fn );
            bands = obj.construct_bands( rho_cp, k, alpha_factor );
            [ m_l, m_r ] = obj.construct_sparse( bands );
            
        end
        
        
        function times = get_last_times( obj )
            
            times = obj.times;
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function values = property_lookup( obj, u, lookup_fn )
            
            tic;
            values = zeros( obj.shape );
            ids = unique( obj.fdm_mesh );
            id_count = numel( ids );
            assert( id_count > 0 );
            for i = 1 : id_count
                
                id = ids( i );
                values( obj.fdm_mesh == id ) = lookup_fn( id, u( obj.fdm_mesh == id ) );
                
            end
            obj.times( end + 1 ) = toc;
            
        end
        
        
        function bands = construct_bands( obj, rho_cp, k, alpha_factor )
            
            tic;
            
            % get mesh for bands
            % index same get convection (h)
            %  loop over ids
            % index differs get conduction (k/dx)
            %  loop over ids
            % all get rho_cp
            %  loop over ids
            
            rho_cp = rho_cp( : );
            half_k_inv = 0.5 ./ k( : );
            bands = cell2mat( arrayfun( @(x)obj.construct_band( rho_cp, half_k_inv, x ), obj.strips, 'uniformoutput', false ) );
            bands = bands .* alpha_factor;
            obj.times( end + 1 ) = toc;
            
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
        
        function band = construct_band( rho_cp, half_k_inv, stride )
            
            band = mean( [ rho_cp circshift( rho_cp, stride ) ], 2 ) .* ...
                ( half_k_inv + circshift( half_k_inv, stride ) );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        element_count
        shape
        strides
        strips
        fdm_mesh
        rho_cp_fn
        k_fn
        
        times
        
        
    end
    
end