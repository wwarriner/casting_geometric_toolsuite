classdef (Sealed) MoldMaterial < Material
    
    methods ( Access = public )
        
        function obj = MoldMaterial( mold_id )
            
            obj = obj@Material( mold_id );
            
        end
        
    end
    
end

