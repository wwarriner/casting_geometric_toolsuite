classdef Sections < Process
    % Sections encapsulates the behavior and data of isolated sections relating
    % to castings. Each isolated sections must be independently fed to ensure
    % sound solidification.
    % Dependencies:
    % - @Mesh
    % - @GeometricProfile
    
    properties ( SetAccess = private )
        count(1,1) uint32
        segments(:,:,:) uint32
        hotspots(:,:,:) uint32
    end
    
    methods
        function obj = Sections( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            obj.obtain_inputs();
            obj.prepare_segment_query();
            obj.prepare_hotspot_query();
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
            common_writer.write_array( obj.NAME, obj.to_array(), obj.mesh.spacing, obj.mesh.origin );
            common_writer.write_table( obj.NAME, obj.to_table() );
        end
        
        function a = to_array( obj )
            a = obj.segments;
        end
        
        function value = to_table( obj )
            value = list2table( ...
                { 'count' }, ...
                { obj.count } ...
                );
        end
        
        function value = get.count( obj )
            value = uint32( obj.segment_query.count );
        end
        
        function value = get.segments( obj )
            value = uint32( obj.segment_query.label_array );
        end
        
        function value = get.hotspots( obj )
            value = uint32( obj.hotspot_query.label_array );
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()
            name = string( mfilename( 'class' ) );
        end
    end
    
    properties ( Access = private )
        mesh Mesh
        profile %geometric or thermal profile
        use_thermal_profile(1,1) logical = false
        segment_query SegmentQuery
        hotspot_query HotspotQuery
    end
    
    methods ( Access = private )
        function obtain_inputs( obj )
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
            end
            assert( ~isempty( obj.mesh ) );
            
            if ~isempty( obj.options )
                FALLBACK_USE_THERMAL_PROFILE = false;
                obj.use_thermal_profile = obj.options.get( ...
                    'processes.thermal_profile.use', ...
                    FALLBACK_USE_THERMAL_PROFILE ...
                    );
            end
            assert( ~isempty( obj.use_thermal_profile ) );
            
            if ~isempty( obj.results )
                if obj.use_thermal_profile
                    thermal_key = ProcessKey( ThermalProfile.NAME );
                    obj.profile = obj.results.get( thermal_key );
                else
                    geometric_key = ProcessKey( GeometricProfile.NAME );
                    obj.profile = obj.results.get( geometric_key );
                end    
            end
            assert( ~isempty( obj.profile ) );
        end
        
        function prepare_segment_query( obj )
            obj.printf( 'Segmenting...\n' );
            obj.segment_query = SegmentQuery( ...
                obj.profile.filtered_interior, ...
                obj.mesh.interior ...
                );
        end
        
        function prepare_hotspot_query( obj )
            obj.printf( 'Finding hotspots...\n' );
            obj.hotspot_query = HotspotQuery( ...
                obj.segments, ...
                obj.profile.filtered_interior ...
                );
        end
    end
    
end
