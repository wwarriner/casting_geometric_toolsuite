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
            
            % apply external bc fn
            ext_bc_fn = @(material_ids,element_ids)1./obj.pp.lookup_ambient_h_values( material_ids, u( element_ids ) );
            b = mesh.apply_external_bc_fns( ext_bc_fn );
            
            A = -A + spdiags2( sum( A, 2 ) + b, 0, A );
            
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

