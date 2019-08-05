classdef (Sealed) Cores < Process
    % @Cores determines core bodies in the cavity exterior by geometrically 
    % expanding the undercuts. Expanded undercuts which overlap are merged,
    % resulting in a number of cores at most equal to the number of undercuts.
    % Judicious choice of @expansion_casting_length can result in far fewer with
    % realistic-looking core bodies.
    % Settings:
    % - @expansion_casting_length, determines cutoff distance for undercut
    % expansion in casting units.
    % Dependencies:
    % - @Mesh
    % - @Undercuts
    
    properties
        expansion_casting_length(1,1) double {mustBeReal,mustBePositive} = inf;
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint32
        label_array(:,:,:) uint32
        volume(1,1) double
    end
    
    methods
        function obj = Cores( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            obj.prepare_cores();
        end
        
        function legacy_run( obj, mesh, undercuts )
            obj.mesh = mesh;
            obj.undercuts = undercuts;
            obj.run();
        end
        
        function write( obj, common_writer )
            common_writer.write_array( obj.NAME, obj.to_array(), obj.mesh.spacing, obj.mesh.origin );
            common_writer.write_table( obj.NAME, obj.to_table() );
        end
        
        function a = to_array( obj )
            a = obj.label_array;
        end
        
        function value = to_table( obj )
            value = list2table( ...
                { 'count' 'volume' }, ...
                { obj.count, obj.volume } ...
                );
        end
        
        function value = get.count( obj )
            value = obj.cores.count;
        end
        
        function value = get.label_array( obj )
            value = obj.cores.label_array;
        end
        
        function value = get.volume( obj )
            voxel_count = sum( obj.label_array > 0, 'all' );
            value = obj.mesh.to_mesh_volume( voxel_count );
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()
            name = string( mfilename( 'class' ) );
        end
    end
    
    methods ( Access = protected )
        function check_settings( obj )
            assert( isfinite( obj.expansion_casting_length ) );
        end
        
        function update_dependencies( obj )
            mesh_key = ProcessKey( Mesh.NAME );
            obj.mesh = obj.results.get( mesh_key );
            
            undercuts_key = ProcessKey( Undercuts.NAME );
            obj.undercuts = obj.results.get( undercuts_key );
            
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.undercuts ) );
        end
    end
    
    methods ( Access = private )
        function prepare_cores( obj )
            obj.printf( 'Evaluating cores by expansion...\n' );
            obj.cores = CoreQuery( ...
                obj.undercuts.label_array > 0, ...
                obj.mesh.exterior, ...
                obj.mesh.to_mesh_length( obj.expansion_casting_length ) ...
                );
        end
    end
    
    properties ( Access = private )
        mesh Mesh
        undercuts Undercuts
        cores CoreQuery
    end
    
end

