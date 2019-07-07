classdef InternalInterfaces < mesh.utils.Interfaces
    
    properties ( GetAccess = public, SetAccess = private )
        is_boundary(:,1) logical = false;
    end
    
    
    properties ( Dependent )
        bc_id_count
        bc_id_list
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
    
    
    methods % getters
        
        function value = get.bc_id_count( obj )
            value = size( obj.bc_id_list, 1 );
        end
        
        function value = get.bc_id_list( obj )
            value = obj.elements.material_ids( obj.element_ids );
            value = sort( value, 2 );
            value( value( :, 1 ) == value( :, 2 ), : ) = [];
            value = unique( value, 'rows' );
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

