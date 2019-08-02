classdef InternalInterfaces < Interfaces
    
    properties ( Dependent )
        bc_id_list
    end
    
    methods
        function obj = InternalInterfaces( ...
                elements, ...
                element_ids, ...
                areas, ...
                distances ...
                )
            obj = obj@Interfaces( ...
                elements, ...
                element_ids, ...
                areas, ...
                distances ...
                );
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
    
end

