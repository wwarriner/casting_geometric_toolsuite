classdef SolidificationKernel < handle
    
    methods
        function obj = SolidificationKernel( physical_properties, mesh, u )
            obj.pp = physical_properties;
            obj.mesh = mesh;
            obj.u = u;
        end
        
        function [ A, b, x0 ] = create_system( obj )
            % material properties
            rho_fn = @(id,locations)obj.pp.lookup_values( id, 'rho', obj.u( locations ) );
            rho = obj.mesh.apply_material_property_fn( rho_fn );
            
            cp_fn = @(id,locations)obj.pp.lookup_values( id, 'cp', obj.u( locations ) );
            cp = obj.mesh.apply_material_property_fn( cp_fn );
            
            k_fn = @(id,locations)obj.pp.lookup_values( id, 'k', obj.u( locations ) );
            k = obj.mesh.apply_material_property_fn( k_fn );
            
            rho_cp_v = rho .* cp .* obj.mesh.volumes;
            
            % apply internal interface fn
            int_res = obj.mesh.apply_internal_interface_fns( @(varargin)obj.internal_resistance_fn(varargin{:},k) );
            
            % apply internal bc fn
            int_bc_fn = @(varargin)obj.internal_bc_fn(varargin{:},obj.u);
            int_bc_res = obj.mesh.apply_internal_bc_fns( int_bc_fn );
            
            int_flow = 1 ./ ( int_res + int_bc_res );
            
            ids = obj.mesh.connectivity;
            lhs = sparse2( ids( :, 1 ), ids( :, 2 ), int_flow, obj.mesh.count, obj.mesh.count );
            lhs = lhs + lhs.';
            
            % apply external bc fn
            ext_bc_fn = @(varargin)obj.external_bc_fn(varargin{:},k,obj.u);
            ext_flow = 1 ./ obj.mesh.apply_external_bc_fns( ext_bc_fn );
            ext_flow( ~isfinite( ext_flow ) ) = 0;
            
            d = sum( lhs, 2 ) + ext_flow;
            A = @(dt) spdiags2( rho_cp_v + d .* dt, 0, -lhs .* dt );
            b = @(dt) rho_cp_v .* obj.u ...
                + dt .* ext_flow .* obj.pp.get_ambient_temperature();
            x0 = obj.u;
        end
    end
    
    properties ( Access = private )
        pp PhysicalProperties
        mesh
        u
    end
    
    methods ( Access = private )
        function values = internal_resistance_fn( obj, element_ids, distances, areas, k )
            values = distances ./ k( element_ids ) ./ areas;
            values = sum( values, 2 );
        end
        
        function values = internal_bc_fn( obj, material_ids, element_ids, distances, areas, u )
            values = 1 ./ obj.pp.lookup_h_values( ...
                material_ids( 1 ), ...
                material_ids( 2 ), ...
                mean( u( element_ids ), 2 ) ...
                ) ./ areas;
        end
        
        function values = external_bc_fn( obj, material_id, element_ids, distances, areas, k, u )
            values = distances ./ k( element_ids );
            values = values + 1 ./ obj.pp.lookup_ambient_h_values( ...
                material_id, ...
                u( element_ids ) ...
                );
            values = values ./ areas;
        end
    end
    
end

