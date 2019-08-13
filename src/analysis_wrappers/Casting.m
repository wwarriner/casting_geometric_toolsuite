classdef Casting < Process
    % @Casting contains information on the geometric abstraction of the shape
    % to be cast during the casting process. It is the starting point for all 
    % downstream operations.
    % Settings:
    % - @input_file, REQUIRED, denotes location in file system for geometry
    % file. Currently only *.stl is supported.
    % Dependencies:
    % - None

    properties
        input_file(1,1) string = ""
    end

    properties ( SetAccess = private, Dependent )
        name(1,1) string
        fv(1,1) struct
        surface_area(1,1) double {mustBeReal,mustBeFinite}
        volume(1,1) double {mustBeReal,mustBeFinite}
        convex_volume(1,1) double {mustBeReal,mustBeFinite}
        centroid(1,3) double {mustBeReal,mustBeFinite}
        envelope(1,1) Envelope
        hole_count(1,1) double {mustBeReal,mustBeFinite}
        flatness(1,1) double {mustBeReal,mustBeFinite}
        ranginess(1,1) double {mustBeReal,mustBeFinite}
        solidity(1,1) double {mustBeReal,mustBeFinite}
        bounding_sphere_diameter(1,1) double {mustBeReal,mustBeFinite}
        %draft_angles(:,1) double {mustBeReal,mustBeFinite} % TODO move into own wrapper
        %draft_fv(1,1) struct
    end
    
    methods
        function obj = Casting( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function legacy_run( obj )
            obj.run();
        end
        
        function rotate( obj, rotation )
            obj.body = obj.body.rotate( rotation );
        end
        
        function write( obj, writer )
            writer.write_fv( obj.NAME, obj.fv )
            %writer.write_colored_fv( strjoin( [ obj.NAME "draft" ], "_" ), obj.draft_fv );
            writer.write_table( obj.NAME, obj.to_table );
        end
        
        function value = get.name( obj )
            value = obj.body.name;
        end
        
        function value = get.fv( obj )
            value = obj.body.fv;
        end
        
        function value = get.surface_area( obj )
            value = obj.body.surface_area;
        end
        
        function value = get.volume( obj )
            value = obj.body.volume;
        end
        
        function value = get.convex_volume( obj )
            value = obj.shape_invariant_query.convex_volume;
        end
        
        function value = get.centroid( obj )
            value = obj.body.centroid;
        end
        
        function value = get.envelope( obj )
            value = obj.body.envelope;
        end
        
        function value = get.hole_count( obj )
            value = obj.shape_invariant_query.hole_count;
        end
        
        function value = get.flatness( obj )
            value = obj.shape_invariant_query.flatness;
        end
        
        function value = get.ranginess( obj )
            value = obj.shape_invariant_query.ranginess;
        end
        
        function value = get.solidity( obj )
            value = obj.shape_invariant_query.solidity;
        end
        
        function value = get.bounding_sphere_diameter( obj )
            value = obj.shape_invariant_query.bounding_sphere_diameter;
        end
        
%         function value = get.draft_angles( obj )
%             value = obj.draft_query.angles;
%         end
%         
%         function value = get.draft_fv( obj )
%             value = obj.body.fv;
%             value.facevertexcdata = obj.draft_angles;
%         end
    end
    
    methods ( Access = public, Static )
        function name = NAME()        
            name = string( mfilename( 'class' ) );
        end
    end
    
    methods ( Access = protected )
        function update_dependencies( ~ )
            % none required
        end
        
        function check_settings( obj )
            assert( obj.input_file ~= "" );
        end
        
        function run_impl( obj )
            obj.read_data();
            obj.prepare_shape_descriptors();
            %obj.prepare_draft();
        end
        
        function value = to_table_impl( obj )
            value = list2table( ...
                { 'surface_area' 'volume' 'convex_volume' ...
                'hole_count' 'flatness' 'ranginess' ...
                'solidity' 'bounding_sphere_diameter' }, ...
                { obj.surface_area obj.volume obj....
                obj.hole_count obj.flatness obj.ranginess ...
                obj.solidity obj.bounding_sphere_diameter } ...
                );
        end
    end
    
    properties ( Access = private )
        stl_file StlFile
        body Body
        shape_invariant_query ShapeInvariantQuery
        draft_query DraftQuery
    end
    
    methods ( Access = private )
        function read_data( obj )
            obj.printf( "Reading casting geometry from file...\n" );
            stl_file_in = StlFile( obj.input_file );
            body_in = Body( stl_file_in.fv );
            body_in.name = stl_file_in.name;
            obj.stl_file = stl_file_in;
            obj.body = body_in;
        end
        
        function prepare_shape_descriptors( obj )
            obj.printf( "  Computing shape descriptors...\n" );
            obj.shape_invariant_query = ShapeInvariantQuery( obj.body );
        end
        
%         function prepare_draft( obj )
%             obj.printf( "  Computing draft...\n" );
%             obj.draft_query = DraftQuery( obj.body.normals, [ 0 0 1 ] );
%         end
    end
    
end

