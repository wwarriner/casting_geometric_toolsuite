classdef Feeders < Process
    % TODO intersection volume, interface area, accessibility
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint32
        fv(:,1) struct
        radius(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        magnitude(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        diameter(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        height(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        area(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        volume(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
    end
    
    methods
        function obj = Feeders( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            obj.obtain_inputs();
            obj.prepare_bodies();
        end
        
        function legacy_run( obj, mesh, sections, geometric_profile )
            obj.mesh = mesh;
            obj.sections = sections;
            obj.geometric_profile = geometric_profile;
            obj.run();
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
        
        function rotate( obj, rotation )
            obj.bodies.rotate( rotation );
        end
        
        function scale( obj, scaling )
            obj.bodies.scale( scaling );
        end
        
        function translate( obj, translation )
            obj.bodies.translate( translation );
        end
        
        function value = to_table( obj )
            value = list2table( ...
                { 'count' }, ...
                { obj.count } ...
                );
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
    
    properties ( Access = private )
        mesh Mesh
        sections Sections
        geometric_profile GeometricProfile
        feeder_query FeederQuery
        bodies(:,1) Body
    end
    
    methods ( Access = private )
        function obtain_inputs( obj )
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
                
                sections_key = ProcessKey( Sections.NAME );
                obj.sections = obj.results.get( sections_key );
                
                geometric_profile_key = ProcessKey( GeometricProfile.NAME );
                obj.geometric_profile = obj.results.get( geometric_profile_key );
            end
            assert( ~isempty( obj.mesh ) );
            assert( ~isempty( obj.sections ) );
            assert( ~isempty( obj.geometric_profile ) );
        end
        
        function prepare_bodies( obj )
            obj.printf( "Generating feeder geometry...\n" );
            fq = FeederQuery( ...
                obj.sections.segments, ...
                obj.sections.hotspots, ...
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
    end
    
end

