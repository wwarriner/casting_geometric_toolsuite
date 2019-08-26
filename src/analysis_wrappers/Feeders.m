classdef Feeders < Process
    
    properties ( SetAccess = private )
        intersection_volume(:,1) double {mustBeReal,mustBeFinite,mustBeNonnegative}
        interface_area(:,1) double {mustBeReal,mustBeFinite,mustBeNonnegative}
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) double
        fv(:,1) struct
        radius(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        magnitude(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        diameter(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        height(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        area(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        volume(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        accessibility(:,1) double {mustBeReal,mustBeFinite,mustBeNonnegative}
    end
    
    methods
        function obj = Feeders( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function legacy_run( obj, mesh, isolated_sections, geometric_profile )
            obj.mesh = mesh;
            obj.isolated_sections = isolated_sections;
            obj.geometric_profile = geometric_profile;
            obj.run();
        end
        
        function rotate( obj, rotation )
            obj.bodies.rotate( rotation );
            obj.prepare_boolean_values();
        end
        
        function value = get.count( obj )
            value = obj.feeder_query.count;
        end
        
        function value = get.fv( obj )
            value = arrayfun( @(b)b.fv, obj.bodies );
        end
        
        function value = get.radius( obj )
            value = obj.mesh.to_casting_length( obj.feeder_query.radius );
        end
        
        function value = get.magnitude( obj )
            value = obj.mesh.to_casting_length( obj.feeder_query.magnitude );
        end
        
        function value = get.diameter( obj )
            value = obj.mesh.to_casting_length( obj.feeder_query.diameter );
        end
        
        function value = get.height( obj )
            value = obj.mesh.to_casting_length( obj.feeder_query.height );
        end
        
        function value = get.area( obj )
            value = obj.mesh.to_casting_area( obj.feeder_query.area );
        end
        
        function value = get.volume( obj )
            value = obj.mesh.to_casting_volume( obj.feeder_query.volume );
        end
        
        function value = get.accessibility( obj )
            value = obj.intersection_volume ./ obj.volume;
            value = min( max( value, 0 ), 1 );
        end
        
        function write( obj, output_files )
            output_files.write_fv_sequence( obj.NAME, obj.fv );
            output_files.write_table( obj.NAME, obj.to_table() );
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()
            name = string( mfilename( 'class' ) );
        end
    end
    
    methods ( Access = protected )
        function update_dependencies( obj )
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
                
                isolated_sections_key = ProcessKey( IsolatedSections.NAME );
                obj.isolated_sections = obj.results.get( isolated_sections_key );
                
                geometric_profile_key = ProcessKey( GeometricProfile.NAME );
                obj.geometric_profile = obj.results.get( geometric_profile_key );
            end
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.isolated_sections ) );
            assert( ~isempty( obj.geometric_profile ) );
        end
        
        function check_settings( obj )
            % no settings need checking
        end
        
        function run_impl( obj )
            obj.prepare_bodies();
            obj.prepare_boolean_values();
        end
        
        function value = to_table_impl( obj )
            value = list2table( ...
                { 'count' 'min_accessibility' ...
                'median_accessibility' 'sum_intersection_volume' ...
                'sum_interface_area' }, ...
                { obj.count min( obj.accessibility ), ...
                median( obj.accessibility ) sum( obj.intersection_volume ) ...
                sum( obj.interface_area ) } ...
                );
        end
    end
    
    properties ( Access = private )
        mesh Mesh
        isolated_sections IsolatedSections
        geometric_profile GeometricProfile
        feeder_query FeederQuery
        bodies(:,1) Body
    end
    
    methods ( Access = private )
        function prepare_bodies( obj )
            obj.printf( "Generating feeder geometry...\n" );
            fq = FeederQuery( ...
                obj.isolated_sections.segments, ...
                obj.isolated_sections.hotspots, ...
                obj.geometric_profile.unscaled ...
                );
            bodies_in = Body.empty( fq.count, 0 );
            fvs = fq.fv;
            % have to scale from axes origin because feeder position is in
            % mesh units and must also be scaled
            scale_origin = [ 0 0 0 ];
            for i = 1 : fq.count
                body = Body( fvs( i ) );
                body = obj.mesh.move_to_casting( body, scale_origin );
                bodies_in( i ) = body;
            end
            obj.feeder_query = fq;
            obj.bodies = bodies_in;
        end
        
        function prepare_boolean_values( obj )
            obj.printf( "  Determining interaction with cavity...\n" );
            iv = zeros( obj.count, 1 );
            ia = zeros( obj.count, 1 );
            for i = 1 : obj.count
                v = obj.mesh.voxelize( obj.bodies( i ) );
                iv( i ) = obj.compute_intersection_volume( v );
                ia( i ) = obj.compute_interface_area( v );
            end
            assert( numel( iv ) == obj.count );
            assert( numel( ia ) == obj.count );
            
            obj.intersection_volume = iv;
            obj.interface_area = ia;
        end
        
        function volume = compute_intersection_volume( obj, voxels )
            intersection = obj.mesh.intersect( voxels.values > 0 );
            intersection_count = sum( intersection, 'all' );
            volume = obj.mesh.to_casting_volume( intersection_count );
        end
        
        function area = compute_interface_area( obj, voxels )
            interface = obj.mesh.intersect( voxels.values > 0 );
            interface_count = sum( interface, 'all' );
            area = obj.mesh.to_casting_volume( interface_count );
        end
    end
    
end

