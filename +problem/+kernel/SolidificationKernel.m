classdef SolidificationKernel < problem.kernel
    
    % abstrac superclass methods
    methods ( Access = public )
        
        function A = create_coefficient_matrix( obj )
            
            % get connectivity
            [ r, c ] = find( mesh.get_connectivity() );
            
            % get material props
            material_ids = mesh.get_material_ids();
            unique_material_ids = mesh.get_unique_material_ids();
            rho = nan( shape( material_ids ) );
            cp = nan( shape( material_ids ) );
            k = nan( shape( material_ids ) );
            for i = 1 : numel( unique_material_ids )
                
                id = unique_material_ids( i );
                inds = material_ids == id;
                us = u( inds );
                rho( inds ) = properties( 'rho', id, us );
                cp( inds ) = properties( 'cp', id, us );
                k( inds ) = properties( 'k', id, us );
                
            end
            assert( ~any( isnan( rho ) ) );
            assert( ~any( isnan( cp ) ) );
            assert( ~any( isnan( k ) ) );
            rho_cp = rho( r ) * cp( r ) + rho( c ) + cp( c );
            k_resistance = 1 ./ k( r ) + 1 ./ k( c );
            
            
            % get internal boundary ids
            internal_boundary_ids = mesh.get_internal_boundary_ids();
            unique_internal_boundary_ids = mesh.get_unique_internal_boundary_ids();
            h = nan( shape( internal_boundary_ids ) );
            for i = 1 : numel( unique_internal_boundary_ids )
                
                id = unique_internal_boundary_ids( i );
                inds = internal_boundary_ids == id;
                us = u( inds );
                h( inds ) = properties( 'h', id, us );
                
            end
            h_resistance = 1 ./ h;
            h_resistance( isnan( h_resistance ) ) = 0;
            
            % apply kernel
            resistance = k_resistance + h_resistance;
            distances = mesh.get_distances();
            areas = mesh.get_areas();
            
            
            
            
            
            % get list of material ids in mesh
            % for each material id
            %  get list of indices
            %  get temperatures at indices
            %  get all relevant properties at those temperatures
            %   rho
            %   cp - special
            %   k
            
            % compute off diagonal entries
            %  elt-wise product of
            %    - distance-weighted harmonic mean conductivity
            %    - reciprocal of distance-weighted mean of product of density and heat cap
            %    - reciprocal of interface area
            %    - time step
            
            distances = mesh.get_distances();
            
            
            % distance comes from mesh interface
            % conductivity comes from material properties
            %
            
            % get list of internal boundary ids in mesh
            % for each boundary id in mesh
            %  get pair of lists of indices
            %  get temperatures at indices
            %  get boundary 
            
        end
        
        
        function b = create_constant_vector( obj )
            
            
            
        end
        
    end
    
end

