classdef AxesWidget < handle
    
    methods ( Access = public )
        
        function obj = AxesWidget( ...
                figure_handle, ...
                corner_pos, ...
                font_size, ...
                button_down_callback ...
                )
            
            DEFAULT_COLOR_MAP = plasma();
            DEFAULT_GRID_COLOR = [ 0 0 0 ];
            
            set( 0, 'currentfigure', figure_handle );
            
            h = axesm( ...
                'pcarree', ...
                'frame', 'on', ...
                'grid', 'on', ...
                'origin', newpole( 90, 0 ), ...
                'glinewidth', 1, ...
                'mlinelocation', 30, ...
                'mlabellocation', 30, ...
                'mlabelparallel', 15, ...
                'meridianlabel', 'on', ...
                'plinelocation', 30, ...
                'plabellocation', 30, ...
                'plabelmeridian', 0, ...
                'parallellabel', 'on', ...
                'labelformat', 'signed', ...
                'gcolor', DEFAULT_GRID_COLOR, ...
                'fontcolor', DEFAULT_GRID_COLOR ...
                );
            colormap( h, DEFAULT_COLOR_MAP );
            
            % axis box
            axis( h, 'tight', 'manual' );
            h.XLim = h.XLim * 1.05;
            h.YLim = h.YLim * 1.05;
            h.Box = 'off';
            
            % axis x label
            h.XAxis.Color = 'none';
            h.XLabel.String = sprintf( ...
                'Azimuth/Rotation @X (%s)', ...
                degree_symbol() ...
                );
            h.XLabel.Color = 'k';
            h.XLabel.Visible = 'on';
            
            % axis y label
            h.YAxis.Color = 'none';
            h.YLabel.String = sprintf( ...
                'Elevation/Rotation @Y (%s)', ...
                degree_symbol() ...
                );
            h.YLabel.Color = 'k';
            h.YLabel.Visible = 'on';
            
            % adjust size
            % todo refactor out
            dims = figure_handle.InnerPosition( 3 : 4 );
            ax_dims = dims * 0.70;
            excess = ( dims - ax_dims ) ./ 2;
            h.Units = 'pixels';
            h.Position = [ excess ax_dims ];
            
            % appearance font
            h.Color = 'none';
            h.FontSize = font_size;
            h.LabelFontSizeMultiplier = 1.0;
            h.TitleFontSizeMultiplier = 1.0;
            
            % callback
            h.ButtonDownFcn = button_down_callback;
            
            % hit test consistency
            ch = h.Children;
            for i = 1 : numel( ch )
                
                ch( i ).HitTest = 'off';
                
            end
            
            pos = h.Position;
            
            % allows widgets to overlap the top/bottom boundaries
            NUDGE_FRACTION = 0.05;
            pos = [ ...
                pos( 1 ) ...
                pos( 2 ) - ( NUDGE_FRACTION * pos( 4 ) ) ...
                pos( 3 ) ...
                pos( 4 ) - ( 2 * NUDGE_FRACTION * pos( 4 ) ) ...
                ];
            
            % places the axes appropriately
            pos = [ ...
                corner_pos ...
                pos( 3 ) ...
                pos( 4 ) ...
                ];
            h.Position = pos;
            
            obj.axes_handle = h;
            
        end
        
        
        function activate( obj, figure_handle )
            
            set( 0, 'currentfigure', figure_handle );
            figure_handle.CurrentAxes = obj.axes_handle;
            
        end
        
        
        function point = get_picked_point( obj )
            
            % gcpmap uses ( theta, phi ) ordering
            point_values = gcpmap( obj.axes_handle );
            phi = point_values( 1, 2 );
            theta = point_values( 1, 1 );
            point = [ phi theta ];
            
        end
        
        
        function update_color_bar( obj, color_bar_range )
            
            original_size = obj.axes_handle.Position;
            
            colorbar( obj.axes_handle, 'off' );
            color_bar_handle = colorbar( obj.axes_handle );
            caxis( [ color_bar_range.min color_bar_range.max ] );
            clim = color_bar_handle.Limits;
            COLORBAR_TICK_COUNT = 11;
            color_bar_handle.Ticks = linspace( ...
                clim( 1 ), ...
                clim( 2 ), ...
                COLORBAR_TICK_COUNT ...
                );
            caxis( obj.axes_handle, 'manual' );
            
            obj.axes_handle.Position = original_size;
            
            pos = color_bar_handle.Position;
            new_pos = pos;
            SCALING_FACTOR = 0.8;
            new_pos( 4 ) = pos( 4 ) * SCALING_FACTOR;
            new_pos( 2 ) = pos( 2 ) + ( pos( 4 ) - new_pos( 4 ) ) / 2;
            color_bar_handle.Position = new_pos;
            
        end
        
        
        function set_color_map( obj, color_map )
            
            colormap( obj.axes_handle, color_map );
            
        end
        
        
        function set_grid_color( obj, grid_color )
            
            setm( obj.axes_handle, 'GColor', grid_color );
            
        end
        
        
        function pos = get_position( obj )
            
            pos = obj.axes_handle.Position;
            
        end
        
        
        function set_position( obj, pos )
            
            obj.axes_handle.Position = pos;
            
        end
        
    end
    
    
    methods ( Access = public )
        
        function height = get_height( obj )
            
            height = obj.axes_handle.Position( 4 );
            
        end
        
        
        function width = get_width( obj )
            
            width = obj.axes_handle.Position( 3 );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        axes_handle
        
    end
    
end

