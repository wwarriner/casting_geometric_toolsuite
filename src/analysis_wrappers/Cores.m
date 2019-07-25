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
        count(1,1) uint64
        label_array(:,:,:) uint64
        volume(1,1)
    end
    
    methods
        function obj = Cores( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            obj.obtain_inputs();
            obj.prepare_core_segments();
        end
        
        function legacy_run( obj, mesh, undercuts, threshold )
            obj.mesh = mesh;
            obj.undercuts = undercuts;
            obj.threshold = threshold;
        end
        
        function write( obj, title, common_writer )
            common_writer.write_array( title, obj.to_array() );
            common_writer.write_table( title, obj.to_table() );
        end
        
        function a = to_array( obj )
            a = obj.label_array;
        end
        
        function value = get.count( obj )
            value = obj.core_segments.count;
        end
        
        function value = get.label_array( obj )
            value = obj.core_segments.label_array;
        end
        
        function value = get.volume( obj )
            voxel_count = sum( obj.core_segments > 0, 'all' );
            value = obj.mesh.to_mesh_volume( voxel_count );
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
                'count' ...
                'volume' ...
                };
        end
        
        function values = get_table_values( obj )
            values = { ...
                obj.count ...
                obj.volume ...
                };
        end
    end
    
    methods ( Access = private )
        function obtain_inputs( obj )
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
        end
        
        function prepare_core_segments( obj )
            obj.printf( 'Evaluating orientation-independent cores...\n' );
            obj.core_segments = CoreSegments( ...
                obj.undercuts.label_array > 0, ...
                obj.mesh.exterior, ...
                obj.mesh.to_mesh_units( obj.threshold ) ...
                );
        end
    end
    
    properties ( Access = private )
        mesh(1,1) Mesh
        undercuts(1,1) Undercuts
        core_segments(1,1) CoreSegments
    end
    
end

