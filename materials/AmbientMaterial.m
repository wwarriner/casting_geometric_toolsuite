classdef (Sealed) AmbientMaterial < Material
    
    methods ( Access = public )
        
        function obj = AmbientMaterial( ambient_id )
            
            obj = obj@Material( ambient_id );
            
        end
        
        
        function nd_material = nondimensionalize( obj, extremes, t_range )
            
            nd_material = AmbientMaterial( obj.get_mesh_id() );
            nd_material = obj.nondimensionalize_impl( nd_material, extremes, t_range );
            
        end
        
    end
    
end

