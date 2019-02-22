classdef (Abstract) Material < handle & matlab.mixin.Heterogeneous
    
    properties ( Access = public )
        
        mesh_id
        
    end
        
    properties ( Access = public, Constant )
        
        NULL_INDEX = 0;
        RHO_INDEX = 1;
        CP_INDEX = 2;
        K_INDEX = 3;
        
    end
    
    
    methods ( Access = public )
        
        nd_material = nondimensionalize( obj, extremes, t_range );
        
    end
    
    
    methods ( Access = public )
        
        function set( obj, material_property )
            
            index = obj.get_type_index( material_property );
            assert( index ~= obj.NULL_INDEX );
            obj.material_properties( index ) = material_property;
            obj.properties_set( index ) = true;
            
        end
        
        
        function set_initial_temperature( obj, initial_temperature )
            
            obj.initial_temperature = initial_temperature;
            obj.initial_temperature_set = true;
            
        end
        
        
        function ready = is_ready( obj )
            
            ready = obj.initial_temperature_set & all( obj.properties_set );
            
        end
        
        
        function material_property = get( obj, index )
            
            assert( obj.is_ready() );
            material_property = obj.material_properties( index );
            
        end
        
        
        function initial_temperature = get_initial_temperature( obj )
            
            assert( obj.is_ready() );
            initial_temperature = obj.initial_temperature;
            
        end
        
        
        function mesh_id = get_mesh_id( obj )
            
            mesh_id = obj.mesh_id;
            
        end
        
        
        function extremes = get_extremes( obj )
            
            assert( obj.is_ready() );
            extremes = zeros( Material.count(), 1 );
            for i = 1 : Material.count()
                
                extremes( i ) = obj.get( i ).get_extreme();
                
            end
            
        end
        
        
        function fns = get_extreme_fns( obj )
            
            fns = cell( Material.count(), 1 );
            for i = 1 : Material.count()
                
                fns{ i } = obj.get( i ).get_extreme_fn();
                
            end
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function count = count()
            
            count = Material.K_INDEX;
            
        end
        
    end
    
    
    properties ( Access = protected )
        
        material_properties
        initial_temperature
        
        properties_set
        initial_temperature_set
        
    end
    
    
    methods ( Access = protected )
        
        function obj = Material( mesh_id )
            
            obj.material_properties = MaterialProperty.empty();
            obj.initial_temperature = [];
            
            obj.properties_set = false( obj.count(), 1 );
            obj.initial_temperature_set = false;
            
            obj.mesh_id = mesh_id;
            
        end
        
        
        function index = get_type_index( obj, material_property )
            
            index = obj.NULL_INDEX;
            if isa( material_property, 'RhoProperty' )
                index = obj.RHO_INDEX;
            elseif isa( material_property, 'CpProperty' )
                index = obj.CP_INDEX;
            elseif isa( material_property, 'KProperty' )
                index = obj.K_INDEX;
            end
            
        end
        
        
        function nd_material = nondimensionalize_impl( obj, nd_material, extremes, t_range )
            
            for i = 1 : obj.count()
                
                nd_material.set( obj.get( i ).nondimensionalize( extremes( i ), t_range ) );
                
            end
            nd_material.set_initial_temperature( scale_temperatures( obj.get_initial_temperature(), t_range ) );
            
        end
        
    end
    
end

