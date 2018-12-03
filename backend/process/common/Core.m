classdef Core < Process
    
    properties ( GetAccess = public, SetAccess = private )
        %% input
        mesh
        undercuts
        distance_threshold_in_stl_units
        
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
                obj.mesh = obj.results.get( Mesh.NAME );
                obj.undercuts = obj.results.get( Undercuts.NAME );
            end
            
            if ~isempty( obj.options )
                obj.distance_threshold_in_stl_units = obj.options.core_distance_threshold_in_stl_units;
            end
            
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.undercuts ) );
            assert( ~isempty( obj.distance_threshold_in_stl_units ) );
            
            obj.printf( 'Evaluating orientation-independent cores...\n' );
            cc = bwconncomp( obj.create_array(), conndef( 3, 'minimal' ) );
            obj.array = labelmatrix( cc );
            
            obj.printf( '  Computing Statistics...\n' );
            obj.count = cc.NumObjects;
            obj.volume = sum( obj.array( : ) > 0 );
            obj.volume_ratio = obj.volume ./ obj.mesh.volume;
            
        end
        
        
        function legacy_run( obj, mesh, undercuts, distance_threshold_in_stl_units )
            
            obj.mesh = mesh;
            obj.undercuts = undercuts;
            obj.distance_threshold_in_stl_units = distance_threshold_in_stl_units;
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
        
        function dependencies = get_dependencies()
            
            dependencies = { ...
                Mesh.NAME, ...
                Undercuts.NAME ...
                };
            
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
            
            threshold = obj.mesh.to_mesh_units( obj.distance_threshold_in_stl_units );
            
        end
        
    end
    
end

