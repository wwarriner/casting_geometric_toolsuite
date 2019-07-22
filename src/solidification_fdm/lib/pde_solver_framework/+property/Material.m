classdef Material < handle & matlab.mixin.Heterogeneous
    
    % TODO rename "MaterialBase"
    
    properties ( Access = public )
        
        mesh_id
        
    end
    
    
    properties ( Access = public, Constant )
        
        NULL = 'null';
        RHO = 'rho';
        CP = 'cp';
        K = 'k';
        FS = 'fs';
        Q = 'q'; % DO NOT SET DIRECTLY
        RHO_CP = 'rho_cp'; % DO NOT SET DIRECTLY
        
    end
    
    
    methods ( Access = public )
        
        function data = read( obj, file )
            
            data = readtable( file );
            
            [ rho_t, rho ] = remove_nans( data.rho_t, data.rho );
            [ cp_t, cp ] = remove_nans( data.cp_t, data.cp );
            [ k_t, k ] = remove_nans( data.k_t, data.k );
            
            obj.set( RhoProperty( rho_t, rho ) );
            obj.set( CpProperty( cp_t, cp ) );
            obj.set( KProperty( k_t, k ) );
            obj.set_initial_temperature( 25 );
            
        end
        
        
        % DO NOT SET Q OR RHO_CP DIRECTLY
        function set( obj, material_property )
            
            assert( ~isa( material_property, 'QProperty' ) );
            assert( ~isa( material_property, 'RhoCpProperty' ) );
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
        
        
        function prepare_for_solver( obj, temperature_range )
            
            assert( ~obj.prepared );
            assert( obj.is_ready() );
            
            obj.material_properties( obj.Q ) = ...
                obj.material_properties( obj.CP ).compute_q_property( temperature_range );
            obj.material_properties( obj.RHO_CP ) = RhoCpProperty( ...
                obj.material_properties( obj.RHO ), ...
                obj.material_properties( obj.CP ) ...
                );
            
            obj.prepared = true;
            
        end
        
        
        function material_property = get( obj, index )
            
            if ~obj.prepared
                assert( strcmpi( index, obj.FS ) );
                assert( obj.properties_set.isKey( obj.FS ) );
            end 
            
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
        
        function obj = Material( mesh_id, file )
            
            if nargin < 2
                file = [];
            end
            
            obj.mesh_id = mesh_id;
            
            obj.material_properties = containers.Map();
            obj.initial_temperature = [];
            
            obj.properties_set = containers.Map();
            obj.initial_temperature_set = false;
            
            obj.prepared = false;
            
            if ~isempty( file )
                try
                    obj.read( file );
                catch e
                    disp( getReport( e ) );
                    assert( false );
                end
            end
            
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

