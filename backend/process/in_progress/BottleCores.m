classdef (Sealed) BottleCores < Process
    
    properties ( GetAccess = public, SetAccess = private )
        %% inputs
        mesh
        profile
        
        %% outputs
        array
        count
        volume
        volume_ratio
        
    end
    
    
    methods ( Access = public )
        
        function obj = BottleCores( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
                
                geometric_profile_key = ProcessKey( GeometricProfile.NAME );
                obj.profile = obj.results.get( geometric_profile_key );
            end
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.profile ) );

            obj.printf( 'Determining bottle cores...\n' );
            ext_filtered_profile = obj.profile.filtered;
            ext_filtered_profile( ~obj.mesh.exterior ) = inf;
            obj.array = watershed( ext_filtered_profile );
            obj.array( ~obj.mesh.exterior ) = 0;
            obj.array = imclearborder( obj.array );
            
            obj.printf( '  Computing statistics...\n' );
            obj.count = numel( unique( obj.array ) ) - 1;
            obj.volume = obj.mesh.to_stl_volume( sum( obj.array(:) > 0 ) );
            obj.volume_ratio = obj.volume ./ obj.mesh.volume;
            
        end
        
        
        function legacy_run( obj, mesh, profile )
            
            obj.mesh = mesh;
            obj.profile = profile;
            obj.run();
            
        end
        
        
        function write( obj, common_writer )
            
            common_writer.write_array( obj.NAME, obj.to_array() );
            common_writer.write_table( obj.NAME, obj.to_table() );
            
        end
        
        
        function a = to_array( obj )
            
            a = obj.array;
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function name = NAME()
            
            name = mfilename( 'class' );
            
        end
        
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
    
end

