classdef ExternalInterfaces < mesh.utils.Interfaces
    
    properties ( Dependent )
        bc_id_list
    end
    
    
    methods ( Access = public )
        
        function obj = ExternalInterfaces( ...
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
        end
        
    end
    
    
    methods % getters
        
        function value = get.bc_id_list( obj )
            value = unique( obj.boundary_ids );
        end
        
    end
    
    
    properties ( Access = protected, Constant )
        COLUMN_COUNT = 1;
    end
    
end

