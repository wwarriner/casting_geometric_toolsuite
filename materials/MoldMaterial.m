classdef (Sealed) MoldMaterial < Material
    
    methods ( Access = public )
        
        function obj = MoldMaterial( mold_id )
            
            obj = obj@Material( mold_id );
            
        end
        
        
        function nd_material = nondimensionalize( obj, extremes, t_range )
            
            nd_material = MoldMaterial( obj.get_mesh_id() );
            nd_material = obj.nondimensionalize_impl( nd_material, extremes, t_range );
            
        end
        
    end
    
end

