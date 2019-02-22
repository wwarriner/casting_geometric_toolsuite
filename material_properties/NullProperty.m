classdef NullProperty < MaterialProperty
    
    methods ( Access = public )
        
        function obj = NullProperty()
            
            obj = obj@MaterialProperty( [], [] );
            
        end
        
    end
    
    
    methods ( Access = public )
        
        function nd_material_property = nondimensionalize( ~, ~, ~ )
            
            nd_material_property = NullProperty();
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function fn = get_extreme_fn( ~ )
            
            fn = @max;
            
        end
        
    end
    
end

