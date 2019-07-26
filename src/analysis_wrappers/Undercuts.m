classdef (Sealed) Undercuts < Process
    % Undercuts encapsulates the behavior and data of casting undercuts for
    % two-piece molding or tooling.
    % Dependencies:
    % - @Mesh
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint32
        label_array(:,:,:) uint32
        volume(1,1) uint32 % stl units
    end
    
    methods
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
        
        function write( obj, common_writer )
            common_writer.write_array( obj.NAME, obj.to_array() );
            common_writer.write_table( obj.NAME, obj.to_table() );
        end
        
        function a = to_array( obj )
            a = obj.undercuts.label_matrix;
        end
        
        function value = to_table( obj )
            value = list2table( ...
                { 'count' 'volume' }, ...
                { obj.count, obj.volume } ...
                );
        end
        
        function value = get.count( obj )
            value = obj.undercuts.count;
        end
        
        function value = get.label_array( obj )
            value = obj.undercuts.label_array;
        end
        
        function value = get.volume( obj )
            value = sum( obj.undercuts.label_matrix > 0, 'all' );
            value = obj.mesh.to_stl_volume( value ); 
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()
            name = mfilename( 'class' );
        end
    end
    
    properties ( Access = private )
        mesh(1,1) Mesh
        undercuts(1,1) UndercutQuery
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
            obj.undercuts = UndercutQuery( obj.mesh.interior );
        end
    end
    
end

