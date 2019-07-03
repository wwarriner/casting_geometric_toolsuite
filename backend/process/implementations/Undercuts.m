classdef (Sealed) Undercuts < Process
    % Undercuts encapsulates the behavior and data of casting undercuts for
    % two-piece molding or tooling.
    
    properties ( GetAccess = public, SetAccess = private )
        count
        volume
    end
    
    
    methods ( Access = public )
        
        function obj = Undercuts( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            obj.obtain_inputs();
            obj.prepare_undercuts();
        end
        
        function legacy_run( obj, mesh )
            obj.mesh = mesh;
            obj.run();
        end
        
        function write( obj, title, common_writer )
            common_writer.write_array( title, obj.to_array() );
            common_writer.write_table( title, obj.to_table() );
        end
        
        function a = to_array( obj )
            a = obj.undercuts.get_as_label_matrix();
        end
        
    end
    
    
    methods % getters
        
        function value = get.count( obj )
            value = obj.undercuts.get_count();
        end
        
        function value = get.volume( obj )
            value = sum( obj.undercuts.get_as_label_matrix() > 0, 'all' );
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
                'volume' ...
                };
        end
        
        function values = get_table_values( obj )
            values = { ...
                obj.count, ...
                obj.volume ...
                };
        end
        
    end
    
    
    properties ( Access = private )
        mesh(1,1) Mesh
        undercuts analyses.Undercuts
    end
    
    
    methods ( Access = private )
        
        function obtain_inputs( obj )
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
            end
            assert( ~isempty( obj.mesh ) );
        end
        
        function prepare_undercuts( obj )
            obj.printf( 'Identifying undercuts...\n' );
            obj.undercuts = analyses.Undercuts( obj.mesh.interior );
        end
        
    end
    
end

