classdef (Sealed) PartingLine < ProcessHelper
    
    properties ( GetAccess = public, SetAccess = private )
        
        lower_bound
        upper_bound
        right_side_distances
        
        input_size
        input_count
        
        parting_line
        flatness
        
    end
    
    
    methods ( Access = public )
        
        function obj = PartingLine( ...
                lower_bound, ...
                upper_bound, ...
                right_side_distances ...
                )
            
            assert( isnumeric( lower_bound ) );
            assert( isnumeric( upper_bound ) );
            assert( isnumeric( right_side_distances ) );
            
            assert( isvector( lower_bound ) );
            assert( isvector( upper_bound ) );
            assert( isvector( right_side_distances ) );
            
            assert( length( lower_bound ) == length( upper_bound ) );
            assert( length( upper_bound ) == length( right_side_distances ) );
            
            obj.lower_bound = lower_bound;
            obj.upper_bound = upper_bound;
            obj.right_side_distances = right_side_distances;
            obj.input_size = size( right_side_distances );
            obj.input_count = length( right_side_distances );
            
            if obj.is_jog_free( lower_bound, upper_bound )
                obj.parting_line = obj.generate_jog_free_path();
            else
                [ lb, ub, rsd, x_scaled ] = obj.wrap_and_scale_inputs();
                starting_path = obj.generate_starting_path( lb, ub );
                path = obj.optimize_path( starting_path, lb, ub, rsd );
                path = obj.straighten_path( path, lb, ub, x_scaled );
                obj.parting_line = obj.prepare_output_path( path );
            end
            obj.flatness = obj.compute_flatness( obj.parting_line, right_side_distances );
            
            assert( all( min( obj.lower_bound ) - 0.5 <= obj.parting_line & obj.parting_line <= max( obj.upper_bound ) + 0.5 ) );
            assert( obj.flatness >= 1 );
            
        end
        
        
        function tr = to_table_row( obj )
            
            tr = { obj.flatness };
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function f = compute_flatness( path_height, right_side_distances )
            
            % 1D version of Flatness criterion
            % from Ravi B and Srinivasa M N, Computer-Aided Design 22(1), pp 11-18
            h = diff( [ path_height path_height( 1 ) ] );
            d = sqrt( h .^ 2 + right_side_distances .^ 2 );
            f = sum( d ) ./ sum( right_side_distances );
            
        end
        
        
        function trn = get_table_row_names()
            
            trn = { 'flatness' };
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function path = generate_jog_free_path( obj )
            
            path_position = mean( obj.determine_gap_extrema( ...
                obj.lower_bound, ...
                obj.upper_bound ...
                ) );
            path = path_position .* ones( obj.input_size );
            
        end
        
        
        function [ lb, ub, rsd, x_scaled ] = wrap_and_scale_inputs( obj )
            
            lb = obj.scale_y( obj.wrap( obj.lower_bound ) );
            ub = obj.scale_y( obj.wrap( obj.upper_bound ) );
            [ rsd, x_scaled ] = obj.scale_x( obj.wrap( obj.right_side_distances ) );
            
        end
        
        
        function [ new_path, loop_count, flatness_values ] = ...
                optimize_path( obj, new_path, lb_w_s, ub_w_s, rsd_w_s )
            
            change = 1;
            flatness_values = [];
            loop_count = 0;
            CHANGE_STOP_VALUE = 1e-5; % TODO make dependent on #elts
            while change > CHANGE_STOP_VALUE
                old_path = new_path;
                shifts = -obj.compute_displacements( old_path, rsd_w_s );
                new_path = min( ub_w_s, max( lb_w_s, old_path + shifts ) ); % physical constraint
                change = max( abs( new_path - old_path ) );
                flatness_values( end + 1 ) = obj.compute_flatness( new_path, rsd_w_s ); %#ok<AGROW>
                loop_count = loop_count + 1;
            end
            
        end
        
        
        function path = straighten_path( obj, path, lb_w_s, ub_w_s, x_s )
            
            pinned_path = ( path <= lb_w_s | ub_w_s <= path );
            pinned_path_indices = find( pinned_path );
            if ~isempty( pinned_path_indices )
                % determination of slopes between pinned (i.e. at UB or LB)
                segment_lengths = diff( [ 0 pinned_path_indices length( path ) ] );
                right_segments = obj.create_segments( ...
                    [ pinned_path_indices pinned_path_indices( 1 ) ], ...
                    segment_lengths ...
                    );
                left_segments = obj.create_segments( ...
                    [ pinned_path_indices( end ) pinned_path_indices ], ...
                    segment_lengths ...
                    );
                x_segments = [ x_s x_s( 1 ) ];
                slopes = ( path( right_segments ) - path( left_segments ) ) ...
                    ./ ( x_segments( right_segments ) - x_segments( left_segments ) );
                
                % straigtening floating segments (i.e. between UB and LB)
                % using slopes
                floating_path = ( lb_w_s < path & path < ub_w_s );
                path( floating_path ) = ...
                    slopes( floating_path ) ...
                    .* ( x_segments( floating_path ) - x_segments( left_segments( floating_path ) ) )...
                    + path( left_segments( floating_path ) );
            else
                % do nothing, path is either straight, or we don't know how to
                % optimize it in a reasonable amount of time
            end
            
        end
        
        
        
        function path = prepare_output_path( obj, path )
            
            path = obj.unscale_y( obj.unwrap( path ) );
            path = path( 1 : obj.input_count );
            
        end
        
        
        function y_scaled = scale_y( obj, y )
            
            bounds = obj.determine_y_bounds();
            interval = diff( bounds );
            y_scaled = ( ( y - min( y ) ) ./ interval ) + ( min( y ) ./ interval );
            
        end
        
        
        function y_interval = determine_y_interval( obj )
            
            y_interval = diff( obj.determine_y_bounds() );
            
        end
        
        
        function y_bounds = determine_y_bounds( obj )
            
            y_bounds = [ min( obj.lower_bound ) max( obj.upper_bound ) ];
            
        end
        
        
        function y = unscale_y( obj, y_scaled )
            
            bounds = obj.determine_y_bounds();
            interval = diff( bounds );
            y = ( y_scaled - ( bounds( 1 ) ./ interval ) ) .* interval + bounds( 1 );
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function displacements = compute_displacements( path, rsd_w_s )
            
            % displacement from straight line for three points
            % y
            left_y = [ path( end ) path ];
            left_y = left_y( 1 : end - 1 );
            right_y = [ path path( 1 ) ];
            right_y = right_y( 2 : end );
            span_y = right_y - left_y;
            
            % x
            right_x = rsd_w_s;
            left_x = circshift( rsd_w_s, 1 );
            span_x = left_x + right_x;
            
            % slope
            slope = span_y ./ span_x;
            straight_line_path = slope .* left_x + left_y;
            displacements = path - straight_line_path;
            
        end
        
        
        function segments = create_segments( ...
                pinned_path_indices, ...
                segment_lengths )
            
            segments = cellfun( ...
                @(x,y) x .* ones( y, 1 ).', ...
                num2cell( pinned_path_indices ), ...
                num2cell( segment_lengths ), ...
                'uniformoutput', false );
            segments = cell2mat( segments );
            
        end
        
        
        function x_wrapped = wrap( x )
            
            full_x = [ x x ];
            x_wrapped = circshift( full_x, floor( length( full_x ) ./ 4 ) );
            
        end
        
        
        function x = unwrap( x_wrap )
            
            x = circshift( x_wrap, -floor( length( x_wrap ) ./ 4 ) );
            
        end
        
        
        function [ right_side_distances_wrap_scale, x_scaled ] = ...
                scale_x( right_side_distances_wrap )
            
            x = cumsum( [ 0 right_side_distances_wrap ] );
            x_scaled = x ./ max( x );
            right_side_distances_wrap_scale = diff( x_scaled );
            x_scaled = cumsum( [ 0 right_side_distances_wrap_scale( 1 : end - 1 ) ] );
            
        end
        
        
        function starting_path = generate_starting_path( ...
                lower_bound_wrap_scale, ...
                upper_bound_wrap_scale ...
                )
            
            starting_path = ( upper_bound_wrap_scale + lower_bound_wrap_scale ) ./ 2;
            
        end
        
        
        function jog_free = is_jog_free( lower_bound, upper_bound )
            
            gap_extrema = PartingLine.determine_gap_extrema( lower_bound, upper_bound );
            jog_free = ( 0 < PartingLine.determine_bounds_gap( gap_extrema ) );
            
        end
        
        
        function bounds_gap = determine_bounds_gap( gap_extrema )
            
            bounds_gap = diff( gap_extrema );
            
        end
        
        
        function gap_extrema = determine_gap_extrema( lower_bound, upper_bound )
            
            gap_extrema = [ max( lower_bound ) min( upper_bound ) ];
            
        end
        
    end
    
end

