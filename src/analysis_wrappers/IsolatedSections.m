classdef IsolatedSections < Process
    % IsolatedSections encapsulates the behavior and data of isolated sections
    % relating to castings. Each isolated sections must be independently fed to
    % ensure sound solidification.
    % Setting:
    % - @use_thermal_profile, dictates whether to make the @ThermalProfile
    % available for certain downstream analyses.
    % Dependencies:
    % - @Mesh
    % - @GeometricProfile
    
    properties
        use_thermal_profile(1,1) logical = false
    end
    
    properties ( SetAccess = private )
        count(1,1) double
        segments(:,:,:) uint32
        hotspots(:,:,:) uint32
    end
    
    methods
        function obj = IsolatedSections( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function legacy_run( obj, geometric_profile, mesh, thermal_profile )
            obj.mesh = mesh;
            obj.profile = geometric_profile;
            if 3 < nargin
                obj.use_thermal_profile = true;
                obj.profile = thermal_profile;
            end
            obj.run();
        end
        
        function write( obj, common_writer )
            common_writer.write_array( obj.NAME, obj.to_array(), obj.mesh.spacing, obj.mesh.origin );
            hotspot_name = strjoin( [ "hotspots" obj.NAME ], "_" );
            common_writer.write_array( hotspot_name, obj.to_array(), obj.mesh.spacing, obj.mesh.origin );
            common_writer.write_table( obj.NAME, obj.to_table() );
        end
        
        function a = to_array( obj )
            a = obj.segments;
        end
        
        function value = get.count( obj )
            value = obj.segment_query.count;
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
        profile % @GeometricProfile or @ThermalProfile
        segment_query SegmentQuery
        hotspot_query HotspotQuery
    end
    
    methods ( Access = protected )
        function check_settings( ~ )
            % no settings need checking
        end
        
        function update_dependencies( obj )
            mesh_key = ProcessKey( Mesh.NAME );
            obj.mesh = obj.results.get( mesh_key );

            if obj.use_thermal_profile
                thermal_key = ProcessKey( ThermalProfile.NAME );
                obj.profile = obj.results.get( thermal_key );
            else
                geometric_key = ProcessKey( GeometricProfile.NAME );
                obj.profile = obj.results.get( geometric_key );
            end  
        end
        
        function run_impl( obj )
            obj.prepare_segment_query();
            obj.prepare_hotspot_query();
        end
        
        function value = to_table_impl( obj )
            value = list2table( ...
                { 'count' }, ...
                { obj.count } ...
                );
        end
    end
    
    methods ( Access = private )
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
