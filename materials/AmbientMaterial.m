classdef (Sealed) AmbientMaterial < Material
    
    methods ( Access = public )
        
        function obj = AmbientMaterial( ambient_id )
            
            obj = obj@Material( ambient_id );
            
        end
        
    end
    
end

