classdef SolidificationKernel < handle
    
    methods ( Access = public )
        
        function obj = SolidificationKernel( physical_properties )
            
            obj.pp = physical_properties;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        pp
        
    end
    
    
    % abstract superclass methods
    methods ( Access = public )
        
        function [ A, b ] = create_system( obj, mesh, u )
            
            % material properties
            rho_fn = @(id,locations)obj.pp.lookup_values( id, 'rho', u( locations ) );
            rho = mesh.apply_material_property_fn( rho_fn );
            
            cp_fn = @(id,locations)obj.pp.lookup_values( id, 'cp', u( locations ) );
            cp = mesh.apply_material_property_fn( cp_fn );
            
            k_fn = @(id,locations)obj.pp.lookup_values( id, 'k', u( locations ) );
            k = mesh.apply_material_property_fn( k_fn );
            
            rho_cp = rho .* cp;
            
            % apply internal interface fn
            int_res = mesh.apply_internal_interface_fns( @(varargin)obj.internal_resistance_fn(varargin{:},k) );
            
            % apply internal bc fn
            int_bc_fn = @(material_ids,element_ids)1./obj.pp.lookup_h_values( material_ids( 1 ), material_ids( 2 ), mean( u( element_ids ), 2 ) );
            int_bc = mesh.apply_internal_bc_fns( int_bc_fn );
            
            int_res = int_res + int_bc;
            
            ids = mesh.get_element_ids();
            A = sparse2( ids( :, 1 ), ids( :, 2 ), int_res, mesh.get_element_count(), mesh.get_element_count() );
            A = A + A.';
            A = A + spdiags2( sum( A, 2 ), 0, A );
            
%             external_bc_function = @
%             
%             external_bc_values = obj.mesh.apply_external_bc_fns( 
            
            % create external BC vector
            %  zero vector of size external interface count by 1
            %  loop over external BC ids
            %   apply BC to interfaces with BC id and add to vector
            
            % create internal BC vector
            %  zero vector of size internal interface count by 1
            %  loop over internal BC ids
            %   apply BC to interfaces with BC id and add to vector
            
            % create internal coefficients
            %  material property lookup
            %  for each property of interest...
            %   zero vector of size element count by 1
            %   loop over material ids
            %    apply property of material to elements with material id
            %    and assign to vector
            %  interface lookup
            %   apply material to 
            
            
            
            
            
            % get connectivity
            cc = mesh.get_connectivity();
            
            % get material props
            material_ids = mesh.get_material_ids();
            unique_material_ids = unique( material_ids );
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
            rho_cp = ...
                rho( cc( :, 1 ) ) * cp( cc( :, 1 ) ) ...
                + rho( cc( :, 2 ) ) * cp( cc( :, 2 ) );
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
        
    end
    
    
    methods ( Access = private, Static )
        
        function values = internal_resistance_fn( element_ids, distances, areas, k )
            values = distances ./ k( element_ids );
            values = sum( values, 2 );
        end
        
        
        function values = internal_bc_fn( material_ids, element_ids )
            
        end
        
    end
    
end

