classdef RubberBandOptimizer < handle
    
    properties
        tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1e-5;
        maximum_iterations(1,1) uint64 {mustBePositive} = 100;
    end
    
    properties ( SetAccess = private )
        path
    end
    
    methods
        function obj = RubberBandOptimizer( lower, upper, distances )
            assert( isa( lower, 'double' ) );
            assert( isvector( lower ) );
            
            assert( isa( upper, 'double' ) );
            assert( isvector( upper ) );
            assert( length( upper ) == length( lower ) );
            assert( all( upper >= lower ) );
            
            assert( isa( distances, 'double' ) );
            assert( isvector( distances ) );
            assert( all( distances > 0 ) );
            assert( length( distances ) == length( lower ) );
            
            obj.lower = fillmissing( lower, 'linear' );
            obj.upper = fillmissing( upper, 'linear' );
            obj.distances = distances;
            obj.count = numel( distances );
            
            if obj.has_gap()
                obj.path = obj.generate_mean_path();
            else
                [ lb, ub, rsd, x_scaled ] = obj.wrap_and_scale();
                path = obj.optimize_path( lb, ub, rsd );
                path = obj.straighten_path( path, lb, ub, x_scaled );
                obj.path = obj.prepare_output_path( path );
            end
            
            assert( all( min( obj.lower ) - 0.5 <= obj.path & obj.path <= max( obj.upper ) + 0.5 ) );
        end
    end
    
    properties ( Access = private )
        lower
        upper
        distances
        count
    end
    
    methods ( Access = private )
        function has = has_gap( obj )
            has = max( obj.lower ) < min( obj.upper );
        end
        
        function path = generate_mean_path( obj )
            height = ( min( obj.upper ) + max( obj.lower ) ) ./ 2;
            path = height .* ones( obj.count, 1 );
        end
        
        function [ lower, upper, distances, x ] = wrap_and_scale( obj )
            lower = obj.scale_y( obj.wrap( obj.lower ) );
            upper = obj.scale_y( obj.wrap( obj.upper ) );
            [ distances, x ] = obj.scale_x( obj.wrap( obj.distances ) );
        end
        
        function y = scale_y( obj, y )
            interval = obj.get_interval();
            y = ( ( y - min( y ) ) ./ interval ) + ( min( y ) ./ interval );
        end
        
        function y = unscale_y( obj, y )
            [ interval, bounds ] = obj.get_interval();
            y = ( y - ( bounds( 1 ) ./ interval ) ) .* interval + bounds( 1 );
        end
        
        function [ interval, bounds ] = get_interval( obj )
            bounds = [ min( obj.lower ) max( obj.upper ) ];
            interval = diff( bounds );
        end
        
        function path = optimize_path( obj, lb, ub, d )
            change = 1;
            iteration = 1;
            path = ( lb + ub ) ./ 2;
            while obj.tolerance < change && iteration <= obj.maximum_iterations
                previous = path;
                shifts = -obj.compute_displacements( previous, d );
                path = min( ub, max( lb, previous + shifts ) ); % physical constraint
                change = max( abs( path - previous ) );
                iteration = iteration + 1;
            end
        end
        
        function path = straighten_path( obj, path, lb, ub, x )
            % finds pinned indices and straightens floating sections between
            % pins
            pinned_path = ( path <= lb | ub <= path );
            if any( pinned_path )
                [ left, right ] = obj.get_circular_indices( pinned_path );
                slopes = obj.determine_slopes( path, left, right, x );
                floating_path = ( lb < path & path < ub );
                path = obj.straighten( path, floating_path, left, slopes, x );
            else
                % do nothing, path is either straight, or optimization failed to
                % pin any indices
            end
        end
        
        function path = prepare_output_path( obj, path )
            path = obj.unscale_y( obj.unwrap( path ) );
            path = path( 1 : obj.count );
        end
    end
    
    methods ( Access = private, Static )
        function v = wrap( v )
            v = [ v; v ];
            v = circshift( v, floor( length( v ) ./ 4 ) );
        end
        
        function x = unwrap( x )
            x = circshift( x, -floor( length( x ) ./ 4 ) );
        end
        
        function [ d, x ] = scale_x( d )
            x = cumsum( [ 0; d ] );
            x = x ./ max( x );
            d = diff( x );
            x = cumsum( [ 0; d( 1 : end - 1 ) ] );
        end
        
        function slopes = determine_slopes( path, left, right, x )
            x = [ x; x( 1 ) ];
            y_seg = path( right ) - path( left );
            x_seg = x( right ) - x( left );
            slopes = y_seg ./ x_seg;
        end
        
        function path = straighten( path, floating_path, left, slopes, x )
            path( floating_path ) = ...
                slopes( floating_path ) ...
                .* ( x( floating_path ) - x( left( floating_path ) ) )...
                + path( left( floating_path ) );
        end
        
        function [ left, right ] = get_circular_indices( path )
            indices = find( path );
            lengths = diff( [ 0; indices; length( path ) ] );
            right = analyses.RubberBandOptimizer.create_segments( [ indices; indices( 1 ) ], lengths );
            left = analyses.RubberBandOptimizer.create_segments( [ indices( end ); indices ], lengths );
        end
        
        function displacements = compute_displacements( path, d )
            left_y = [ path( end ); path ];
            left_y = left_y( 1 : end - 1 );
            right_y = [ path; path( 1 ) ];
            right_y = right_y( 2 : end );
            span_y = right_y - left_y;
            
            right_x = d;
            left_x = circshift( d, 1 );
            span_x = left_x + right_x;
            
            slope = span_y ./ span_x;
            straight_line_path = slope .* left_x + left_y;
            displacements = path - straight_line_path;
        end
        
        function segments = create_segments( indices, lengths )
            segments = cellfun( ...
                @(x,y) x .* ones( y, 1 ), ...
                num2cell( indices ), ...
                num2cell( lengths ), ...
                'uniformoutput', false ...
                );
            segments = cell2mat( segments );
        end
    end
    
end

