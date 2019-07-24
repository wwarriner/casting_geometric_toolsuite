classdef (Sealed) PartingPerimeter < Process
    
    properties ( SetAccess = private )
        mesh
        perimeter
    end
    
    properties ( SetAccess = private, Dependent )
        draw
    end
    
    methods ( Access = public )
        function obj = PartingPerimeter( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
            end
            assert( ~isempty( obj.mesh ) );
            
            obj.printf( ...
                'Locating parting perimeter...\n', ...
                obj.parting_dimension ...
                );
            obj.perimeter = analyses.PartingPerimeter( obj.mesh.interior );
        end
        
        function legacy_run( obj, mesh )
            obj.mesh = mesh;
            obj.run();
        end
        
        function write( obj, title, common_writer )
            % TODO consider how to manage this
            common_writer.write_array( title, obj.to_array() );
            common_writer.write_table( title, obj.to_table() );
        end
        
        function a = to_array( obj )
            a = double( obj.perimeter.binary_array );
            b = obj.perimeter.jog_free.binary_array;
            a( b ) = 2;
            b = obj.perimeter.line.binary_array;
            a( b ) = 3;
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()
            name = mfilename( 'class' );
        end
    end
    
    methods ( Access = protected )
        function names = get_table_names( obj )
            names = {}; % TODO
        end
        
        function values = get_table_values( obj )
            values = []; % TODO
        end
    end
    
end

