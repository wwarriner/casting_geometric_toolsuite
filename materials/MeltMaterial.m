classdef (Sealed) MeltMaterial < Material
    
    properties ( Access = public, Constant )
        
        FS_INDEX = 4;
        
    end
    
    
    methods ( Access = public )
        
        function obj = MeltMaterial( mesh_id )
            
            obj = obj@Material( mesh_id );
            obj.feeding_effectivity = [];
            obj.feeding_effectivity_set = false;
            
        end
        
        
        function set_feeding_effectivity( obj, feeding_effectivity )
            
            assert( isscalar( feeding_effectivity ) );
            assert( isa( feeding_effectivity, 'double' ) );
            assert( 0 <= feeding_effectivity );
            assert( feeding_effectivity <= 1 );
            
            obj.feeding_effectivity = feeding_effectivity;
            obj.feeding_effectivity_set = true;
            
        end
        
        
        function ready = is_ready( obj )
            
            ready = obj.is_ready@Material() & obj.feeding_effectivity_set;
            
        end
        
        
        function feeding_effectivity = get_feeding_effectivity( obj )
            
            feeding_effectivity = obj.feeding_effectivity;
            
        end
        
        
        function temperature = get_feeding_effectivity_temperature( obj )
            
            temperature = obj.get( obj.FS_INDEX ).lookup_temperatures( obj.feeding_effectivity );
            
        end
        
        
        function nd_material = nondimensionalize( obj, extremes, t_range )
            
            nd_material = MeltMaterial( obj.get_mesh_id() );
            extremes( obj.FS_INDEX ) = obj.get( obj.FS_INDEX ).get_extreme();
            nd_material.set_feeding_effectivity( obj.get_feeding_effectivity() );
            nd_material = obj.nondimensionalize_impl( nd_material, extremes, t_range );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function count = count()
            
            count = MeltMaterial.FS_INDEX;
            
        end
        
    end
    
    
    properties ( Access = protected )
        
        feeding_effectivity
        feeding_effectivity_set
        
    end
    
end

