classdef (Abstract) Result < handle
    
    methods ( Access = public )
        
        update( obj, mesh, physical_properties, iterator, problem );
        field = get_scalar_field( obj );
        
    end
    
end

