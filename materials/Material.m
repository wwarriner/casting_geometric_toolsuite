classdef (Abstract) Material < handle & matlab.mixin.Heterogeneous
    
    properties ( Access = public )
        
        mesh_id
        
    end
    
    properties ( Access = public, Constant )
        
        NULL = 'null';
        RHO = 'rho';
        CP = 'cp';
        K = 'k';
        FS = 'fs';
        K_INV = 'k_inv'; % DO NOT SET DIRECTLY
        Q = 'q'; % DO NOT SET DIRECTLY
        
    end
    
    
    methods ( Access = public )
        
        % DO NOT SET K_INV OR Q DIRECTLY
        function set( obj, material_property )
            
            assert( ~obj.prepared );
            
            index = obj.get_type_index( material_property );
            assert( ~strcmpi( index, obj.NULL ) );
            obj.material_properties( index ) = material_property;
            obj.properties_set( index ) = true;
            
        end
        
        
        function set_initial_temperature( obj, initial_temperature )
            
            assert( ~obj.prepared );
            
            obj.initial_temperature = initial_temperature;
            obj.initial_temperature_set = true;
            
        end
        
        
        function initial_temperature = get_initial_temperature( obj )
            
            initial_temperature = obj.initial_temperature;
            
        end
        
        
        function ready = is_ready( obj )
            
            ready = obj.initial_temperature_set;
            ready = ready & obj.properties_set.isKey( obj.RHO );
            ready = ready & obj.properties_set.isKey( obj.CP );
            ready = ready & obj.properties_set.isKey( obj.K );
            
        end
        
        
        function prepare_for_solver( obj, space_step, temperature_range )
            
            assert( obj.is_ready() );
            
            obj.material_properties( obj.K_INV ) = ...
                obj.material_properties( obj.K ).compute_k_half_space_step_inverse_property( space_step );
            obj.material_properties( obj.Q ) = ...
                obj.material_properties( obj.CP ).compute_q_property( temperature_range );
            
            obj.prepared = true;
            
        end
        
        
        function material_property = get( obj, index )
            
            assert( obj.prepared );
            material_property = obj.material_properties( index );
            
        end
        
        
        function mesh_id = get_mesh_id( obj )
            
            mesh_id = obj.mesh_id;
            
        end
        
    end
    
    
    properties ( Access = protected )
                
        material_properties
        initial_temperature
        
        properties_set
        initial_temperature_set
        
        prepared
        
    end
    
    
    methods ( Access = protected )
        
        function obj = Material( mesh_id )
            
            obj.mesh_id = mesh_id;
            
            obj.material_properties = containers.Map();
            obj.initial_temperature = [];
            
            obj.properties_set = containers.Map();
            obj.initial_temperature_set = false;
            
            obj.prepared = false;
            
        end
        
        
        function index = get_type_index( obj, material_property )
            
            index = obj.NULL;
            if isa( material_property, 'RhoProperty' )
                index = obj.RHO;
            elseif isa( material_property, 'CpProperty' )
                index = obj.CP;
            elseif isa( material_property, 'KProperty' )
                index = obj.K;
            end
            
        end
        
    end
    
end

