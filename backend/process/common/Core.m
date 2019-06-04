classdef Core < Process
    
    properties ( GetAccess = public, SetAccess = private )
        %% input
        mesh
        undercuts
        threshold_stl_units
        
        %% output
        array
        count
        volume
        volume_ratio
        
    end
    
    
    methods ( Access = public )
        
        function obj = Core( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
                
                undercuts_key = ProcessKey( Undercuts.NAME, obj.parting_dimension );
                obj.undercuts = obj.results.get( undercuts_key );
            end
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.undercuts ) );
            
            if ~isempty( obj.options )
                FALLBACK_THRESHOLD_STL_UNITS = 25; % mm;
                obj.threshold_stl_units = obj.options.get( ...
                    'processes.core.threshold_stl_units', ...
                    FALLBACK_THRESHOLD_STL_UNITS ...
                    );
            end
            assert( ~isempty( obj.threshold_stl_units ) );
            
            obj.printf( 'Evaluating orientation-independent cores...\n' );
            cc = bwconncomp( obj.create_array(), conndef( 3, 'maximal' ) );
            obj.array = labelmatrix( cc );
            
            obj.printf( '  Computing Statistics...\n' );
            obj.count = cc.NumObjects;
            obj.volume = obj.mesh.to_stl_volume( sum( obj.array( : ) > 0 ) );
            obj.volume_ratio = obj.volume ./ obj.mesh.volume;
            
        end
        
        
        function legacy_run( obj, mesh, undercuts, threshold_stl_units )
            
            obj.mesh = mesh;
            obj.undercuts = undercuts;
            obj.threshold_stl_units = threshold_stl_units;
            obj.run();
            
        end
        
        
        function write( obj, title, common_writer )
            
            common_writer.write_array( title, obj.to_array() );
            common_writer.write_table( title, obj.to_table() );
            
        end
        
        
        function a = to_array( obj )
            
            a = obj.array;
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function orientation_dependent = is_orientation_dependent()
            
            orientation_dependent = true;
            
        end
        
        
        function gravity_direction = has_gravity_direction()
            
            gravity_direction = false;
            
        end
        
    end
    
    
    methods ( Access = protected, Abstract )
        
        create_array( obj );
        
    end
    
    
    methods ( Access = protected )
        
        function names = get_table_names( ~ )
            
            names = { ...
                'count', ...
                'volume_ratio' ...
                };
            
        end
        
        
        function values = get_table_values( obj )
            
            values = { ...
                obj.count, ...
                obj.volume_ratio ...
                };
            
        end
        
    end
    
    
    methods ( Access = protected, Sealed )
        
        function threshold = get_threshold( obj )
            
            threshold = obj.mesh.to_mesh_units( obj.threshold_stl_units );
            
        end
        
    end
    
end

