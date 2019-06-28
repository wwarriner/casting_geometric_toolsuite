classdef (Abstract) MeshInterface < handle
    
    methods ( Access = public )
        
        add_component( obj, component );
        build( obj );
        
        assign_uniform_external_boundary_id( obj, id );
        assign_external_boundary_id( obj, id, interface_ids );
        
    end
    
end

