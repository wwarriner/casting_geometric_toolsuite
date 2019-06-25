classdef ComponentInterface < handle
    
    methods ( Access = public )
        
        id = get_material_id( obj );
        representation = get_geometric_representation( obj );
        
    end
    
end

