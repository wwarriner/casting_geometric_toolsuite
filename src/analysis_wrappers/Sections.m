classdef (Sealed) Sections < Process
    % Sections encapsulates the behavior and data of isolated sections relating
    % to castings. Each isolated sections must be independently fed to ensure
    % sound solidification.
    
    properties ( SetAccess = private )
        count(1,1) uint64
        segment_label(:,:,:) uint64
    end
    
    methods
        function obj = Sections( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            obj.obtain_inputs();
            obj.prepare_segments();
        end
        
        function legacy_run( obj, geometric_profile, mesh, thermal_profile )
            obj.mesh = mesh;
            obj.geometric_profile = geometric_profile;
            if 3 < nargin
                obj.use_thermal_profile = true;
                obj.thermal_profile = thermal_profile;
            end
            obj.run();
        end
        
        function write( obj, common_writer )
            common_writer.write_array( obj.NAME, obj.to_array() );
            common_writer.write_table( obj.NAME, obj.to_table() );
        end
        
        function a = to_array( obj )
            a = obj.segment_label;
        end
        
        function value = get.count( obj )
            value = obj.segments.count;
        end
        
        function value = get.segment_label( obj )
            value = obj.segments.label_array;
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
                };
        end
        
        function values = get_table_values( obj )
            values = { ...
                obj.count ...
                };
        end
    end
    
    
    properties ( Access = private )
        mesh(1,1) Mesh
        geometric_profile(1,1) GeometricProfile
        use_thermal_profile(1,1) logical = false
        profile double {mustBeReal,mustBeFinite}
        segments Segments
    end
    
    
    methods ( Access = private )
        function obtain_inputs( obj )
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
            end
            assert( ~isempty( obj.mesh ) );
            
            if ~isempty( obj.results )
                geometric_profile_key = ProcessKey( GeometricProfile.NAME );
                obj.geometric_profile = obj.results.get( geometric_profile_key );
            end
            assert( ~isempty( obj.geometric_profile ) );
            
            if ~isempty( obj.options )
                FALLBACK_USE_THERMAL_PROFILE = false;
                obj.use_thermal_profile = obj.options.get( ...
                    'processes.thermal_profile.use', ...
                    FALLBACK_USE_THERMAL_PROFILE ...
                    );
            end
            assert( ~isempty( obj.use_thermal_profile ) );
        end
        
        function prepare_segments( obj )
            obj.printf( 'Segmenting...\n' );
            if obj.use_thermal_profile
                thermal_profile_key = ProcessKey( ThermalProfile.NAME );
                obj.profile = obj.results.get( thermal_profile_key );
                % TODO fix incorrect assignment
            else
                obj.profile = obj.geometric_profile.scaled_interior;
            end
            assert( ~isempty( obj.profile ) );
            obj.segments = Segments( ...
                obj.profile, ...
                obj.mesh.interior ...
                );
        end
    end
    
end
