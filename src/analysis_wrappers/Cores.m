classdef (Sealed) Cores < Process
    % @Cores determines core bodies in the cavity exterior by expanding the
    % undercuts.
    % Settings:
    % - @threshold, determines cutoff distance for undercut expansion in
    % component units.
    % Dependencies:
    % - @Mesh
    % - @Undercuts
    
    properties
        threshold(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1 % component units
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint32
        label_array(:,:,:) uint32
        volume(1,1)
    end
    
    methods
        function obj = Cores( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            obj.obtain_inputs();
            obj.prepare_cores();
        end
        
        function legacy_run( obj, mesh, undercuts, threshold )
            obj.mesh = mesh;
            obj.undercuts = undercuts;
            obj.threshold = threshold;
        end
        
        function write( obj, common_writer )
            common_writer.write_array( obj.NAME, obj.to_array() );
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
            voxel_count = sum( obj.cores > 0, 'all' );
            value = obj.mesh.to_mesh_volume( voxel_count );
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()
            name = mfilename( 'class' );
        end
    end
    
    methods ( Access = private )
        function obtain_inputs( obj )
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
                
                undercuts_key = ProcessKey( Undercuts.NAME );
                obj.undercuts = obj.results.get( undercuts_key );
            end
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.undercuts ) );
            
            if ~isempty( obj.options )
                FALLBACK_THRESHOLD = 25; % mm;
                obj.threshold = obj.options.get( ...
                    'processes.core.threshold_stl_units', ...
                    FALLBACK_THRESHOLD ...
                    );
            end
            assert( ~isempty( obj.threshold ) );
        end
        
        function prepare_cores( obj )
            obj.printf( 'Evaluating orientation-independent cores...\n' );
            obj.cores = CoreQuery( ...
                obj.undercuts.label_array > 0, ...
                obj.mesh.exterior, ...
                obj.mesh.to_mesh_units( obj.threshold ) ...
                );
        end
    end
    
    properties ( Access = private )
        mesh(1,1) Mesh
        undercuts(1,1) Undercuts
        cores(1,1) CoreQuery
    end
    
end

