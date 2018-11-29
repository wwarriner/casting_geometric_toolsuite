classdef (Sealed) PrettyAxes3D < handle & matlab.mixin.Copyable
    
    methods ( Access = public )
        
        function obj = PrettyAxes3D( varargin )
            
            switch numel( varargin )
                case 0
                    obj.min_point = [];
                    obj.max_point = [];
                    obj.origin = zeros( 3, 1 );
                case 1
                    obj.min_point = [];
                    obj.max_point = [];
                    obj.origin = varargin{ 1 }( : );
                case 2
                    obj.min_point = varargin{ 1 }( : ).';
                    obj.max_point = varargin{ 2 }( : ).';
                    obj.origin = zeros( 3, 1 );
                case 3
                    obj.min_point = varargin{ 1 }( : ).';
                    obj.max_point = varargin{ 2 }( : ).';
                    obj.origin = varargin{ 3 }( : );
            end
            
            obj.colors = obj.default_colors();
            obj.scaling_factor = obj.DEFAULT_SCALING_FACTOR;
            obj.pos_neg_labels = obj.default_pos_neg_labels();
            obj.axis_labels = obj.default_axis_labels();
            
        end
        
        
        function draw( obj, axes_handle )
            
            if nargin < 2
                axes_handle = gca();
            end
            
            if ~ishold( axes_handle )
                hold( axes_handle, 'on' );
                old_hold_state = 'off';
            else
                old_hold_state = 'on';
            end
            
            [ min_pt, max_pt ] = obj.get_extrema( axes_handle );
            
            obj.plot_axis_lines( axes_handle, min_pt );
            obj.plot_axis_lines( axes_handle, max_pt );
            obj.plot_text_labels( axes_handle, min_pt, +1 );
            obj.plot_text_labels( axes_handle, max_pt, -1 );
            
            hold( axes_handle, old_hold_state );
            
        end
        
        
        function set_colors( obj, colors )
            
            assert( ...
                isnumeric( colors ) ...
                && ismatrix( colors ) ...
                && all( size( colors ) == [ 3 3 ] ) ...
                );
            obj.colors = colors;
            
        end
        
        
        function set_pos_neg_labels( obj, labels )
            
            assert( ischar( labels ) && length( labels ) >= 2 );
            obj.pos_neg_labels = labels;
            
        end
        
        
        function set_axis_labels( obj, labels )
            
            assert( ischar( labels ) && length( labels ) >= 3 );
            obj.axis_labels = labels;
            
        end
        
        
        function set_scaling_factor( obj, factor )
            
            obj.scaling_factor = factor;
            
        end
        
        
        function use_axes_min_point( obj )
            
            obj.set_min_point( [] );
            
        end
        
        
        function use_axes_max_point( obj )
            
            obj.set_max_point( [] );
            
        end
        
        
        function set_min_point( obj, point )
            
            obj.min_point = point;
            
        end
        
        
        function set_max_point( obj, point )
            
            obj.max_point = point;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        min_point
        max_point
        origin
        colors
        scaling_factor
        pos_neg_labels
        axis_labels
        
    end
    
    
    properties ( Access = private, Constant )
        
        DEFAULT_SCALING_FACTOR = 1.2;
        LABEL_SCALING_FACTOR = 1.1;
        
    end
    
    
    methods ( Access = private )
        
        function plot_axis_lines( obj, axes_handle, extreme )
            
            for i = 1 : 3
                
                extents = repmat( obj.origin, [ 1 2 ] );
                extents( i, 2 ) = extreme( i );
                plot3( ...
                    axes_handle, ...
                    extents( 1, : ), ...
                    extents( 2, : ), ...
                    extents( 3, : ), ...
                    'color', obj.get_color( i ) ...
                    );
                
            end
            
        end
        
        
        function plot_text_labels( obj, axes_handle, extreme, direction )
            
            extreme = extreme * obj.LABEL_SCALING_FACTOR;
            for i = 1 : 3
                
                extents = obj.origin;
                extents( i ) = extreme( i );
                handle = text( ...
                    axes_handle, ...
                    extents( 1 ), ...
                    extents( 2 ), ...
                    extents( 3 ), ...
                    obj.get_label_string( i, direction ) ...
                    );
                obj.format_text( handle, obj.get_color( i ) );
                
            end
            
        end
        
        
        function [ min_pt, max_pt ] = get_extrema( obj, axes_handle )
            
            extrema = [ ...
                xlim( axes_handle ); ...
                ylim( axes_handle ); ...
                zlim( axes_handle ) ...
                ].';
            if ~isempty( obj.min_point )
                extrema( 1, : ) = obj.min_point;
            end
            if ~isempty( obj.max_point )
                extrema( 2, : ) = obj.max_point;
            end
            extrema = sort( extrema ) + obj.get_extensions( extrema );
            min_pt = extrema( 1, : );
            max_pt = extrema( 2, : );
        
        end
        
        
        function extensions = get_extensions( obj, extrema )
            
            base_extension = max( abs( extrema ) ) * ( obj.scaling_factor - 1 );
            extensions = ...
                base_extension .* ...
                sign( extrema ) .* ...
                ones( size( extrema ) );
            
        end
        
        
        function label = get_label_string( obj, axis_index, direction )
            
            if direction < 0
                sign = obj.pos_neg_labels( 1 );
            elseif direction > 0
                sign = obj.pos_neg_labels( 2 );
            else
                assert( false );
            end
            label = sprintf( '%s%s', sign, obj.axis_labels( axis_index ) );
            
        end
        
        
        function color = get_color( obj, axis_index )
            
            color = obj.colors( axis_index, : );
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function colors = default_colors()
            
            red = [ 230 52 52 ] / 255;
            yellow = [ 240 196 79 ] / 255;
            green = [ 74 217 148 ] / 255;
            colors = [ red; yellow; green ];
            
        end
        
        
        function labels = default_pos_neg_labels()
            
            labels = '-+';
            
        end
        
        
        function labels = default_axis_labels()
            
            labels = 'XYZ';
            
        end
        
        
        function format_text( text_handle, color )
            
            text_handle.Color = color;
            text_handle.HorizontalAlignment = 'center';
            text_handle.VerticalAlignment = 'middle';
            
        end
        
    end
    
end

