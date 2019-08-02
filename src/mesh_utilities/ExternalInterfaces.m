classdef ExternalInterfaces < Interfaces
    
    properties ( Dependent )
        bc_id_list
    end
    
    methods
        function obj = ExternalInterfaces( ...
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
            value = unique( obj.boundary_ids );
        end
    end
    
    properties ( Access = protected, Constant )
        COLUMN_COUNT = 1;
    end
    
end

