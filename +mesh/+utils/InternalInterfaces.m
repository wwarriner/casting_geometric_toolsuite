classdef InternalInterfaces < mesh.utils.Interfaces
    
    properties ( Access = public )
        
        is_boundary(:,1) logical = false;
        
    end
    
    
    methods ( Access = public )
        
        function obj = InternalInterfaces( ...
                elements, ...
                element_ids, ...
                areas, ...
                distances ...
                )
            
            obj = obj@mesh.utils.Interfaces( ...
                elements, ...
                element_ids, ...
                areas, ...
                distances ...
                );
            obj.is_boundary = obj.determine_boundaries();
            
        end
        
    end
    
    
    properties ( Access = protected, Constant )
        
        COLUMN_COUNT = 2;
        
    end
    
    
    methods ( Access = private )
        
        function boundaries = determine_boundaries( obj )
            
            component_ids = obj.elements.component_ids( obj.element_ids );
            boundaries = component_ids( :, 1 ) ~= component_ids( :, 2 );
            
        end
        
    end
    
end

