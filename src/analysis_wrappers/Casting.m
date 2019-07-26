classdef Casting < Process
    
    properties ( SetAccess = private )
        envelope Envelope
        surface_area(1,1) double {mustBeReal,mustBeFinite}
        volume(1,1) double {mustBeReal,mustBeFinite}
        hole_count(1,1) double {mustBeReal,mustBeFinite}
        flatness(1,1) double {mustBeReal,mustBeFinite}
        ranginess(1,1) double {mustBeReal,mustBeFinite}
        solidity(1,1) double {mustBeReal,mustBeFinite}
        centroid(1,3) double {mustBeReal,mustBeFinite}
        draft_angles(:,1) double {mustBeReal,mustBeFinite}
        draft(1,1) struct
    end
    
    methods
        function obj = Casting( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            obj.obtain_inputs();
            obj.read_data();
            obj.prepare_shape_descriptors();
        end
        
        function legacy_run( obj, file )
            obj.file = file;
            obj.run();
        end
        
        function rotate( obj, rotator )
            
        end
        
        function scale( obj, factor )
            
        end
        
        function to_table( obj )
            
        end
        
        function write( obj, writer )
            writer.write_fv( obj.NAME, obj.fv )
            writer.write_colored_fv( [ obj.NAME '_draft' ], obj.draft );
            writer.write_table( obj.NAME, obj.to_table );
        end
        
        function value = get.envelope( obj )
            value = obj.body.envelope;
        end
        
        function value = get.surface_area( obj )
            value = obj.shape_query.surface_area;
        end
        
        function value = get.volume( obj )
            value = obj.shape_query.volume;
        end
        
        function value = get.hole_count( obj )
            value = obj.shape_query.hole_count;
        end
        
        function value = get.flatness( obj )
            value = obj.shape_query.flatness;
        end
        
        function value = get.ranginess( obj )
            value = obj.shape_query.ranginess;
        end
        
        function value = get.solidity( obj )
            value = obj.shape_query.solidity;
        end
        
        function value = get.centroid( obj )
            value = obj.shape_query.centroid;
        end
        
        function value = get.draft_angles( obj )
            % TODO make DraftQuery
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()        
            name = mfilename( 'class' );
        end
    end
    
    properties ( Access = private )
        file(1,1) string
        stl_file StlFile
        body Body
        convex_hull ConvexHull
        shape_query ShapeQuery
    end
    
    methods ( Access = private )
        function obtain_inputs( obj )
            if ~isempty( obj.options )
                loc = 'manager.stl_file';
                obj.file = obj.options.get( loc );
            end
            assert( ~isempty( obj.file ) );
        end
        
        function read_data( obj )
            stl_file_in = StlFile( obj.file );
            obj.stl_file = stl_file_in;
            obj.body = body_in;
            obj.convex_hull = convex_hull_in;
        end
        
        function prepare_shape_descriptors( obj )
            obj.body = Body( obj.stl_file.fv );
            obj.convex_hull = ConvexHull( obj.stl_file.fv );
            obj.shape_query = ShapeQuery( obj.stl_file.fv, obj.convex_hull );
        end
    end
    
end

