classdef (Sealed) MeltMaterial < Material
    
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
            
            ready = obj.is_ready@Material();
            ready = ready & obj.feeding_effectivity_set;
            ready = ready & obj.properties_set.isKey( obj.FS );
            
        end
        
        
        function feeding_effectivity = get_feeding_effectivity( obj )
            
            feeding_effectivity = obj.feeding_effectivity;
            
        end
        
        
        function temperature = get_liquidus_temperature( obj )
            
            temperature = obj.get( obj.FS ).get_liquidus();
            
        end
        
        
        function temperature = get_feeding_effectivity_temperature( obj )
            
            temperature = obj.get_fraction_solid_temperature( obj.feeding_effectivity );
            
        end
        
        
        function temperature = get_solidus_temperature( obj )
            
            temperature = obj.get( obj.FS ).get_solidus();
            
        end
        
        
        function temperature = get_fraction_solid_temperature( obj, fraction_solid )
            
            temperature = obj.get( obj.FS ).lookup_temperatures( fraction_solid );
            
        end
        
        
        function latent_heat = get_latent_heat( obj )
            
            liquidus = obj.material_properties( obj.FS ).get_liquidus();
            solidus = obj.material_properties( obj.FS ).get_solidus();
            latent_heat = ...
                obj.material_properties( obj.Q ).get_latent_heat( liquidus, solidus );
            
        end
        
        
        function sensible_heat = get_sensible_heat( obj )
            
            liquidus = obj.material_properties( obj.FS ).get_liquidus();
            solidus = obj.material_properties( obj.FS ).get_solidus();
            sensible_heat = ...
                obj.material_properties( obj.Q ).get_sensible_heat( liquidus, solidus );
            
        end
        
    end
    
    
    properties ( Access = protected )
        
        feeding_effectivity
        feeding_effectivity_set
        
    end
    
    
    methods ( Access = protected )
        
        function index = get_type_index( obj, material_property )
            
            index = obj.get_type_index@Material( material_property );
            if isa( material_property, 'FsProperty' )
                index = obj.FS;
            end
            
        end
        
    end
    
end

