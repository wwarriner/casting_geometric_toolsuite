classdef (Abstract) MeshInterface < handle
    
    properties ( GetAccess = public, SetAccess = protected )
        
        elements
        interfaces_in
        interfaces_ex
        
    end
    
    
    methods ( Access = public )
        
        add_component( obj, component );
        assign_default_external_boundary_id( obj, id );
        assign_external_boundary_id( obj, id, interface_ids );
        
        build( obj );
        
    end
    
end

