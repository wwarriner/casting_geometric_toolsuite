classdef (Sealed) UnitSphereResponseAxes < handle
    
    methods ( Access = public )
        
        
        function obj = UnitSphereResponseAxes( color_map, grid_color )
            
            if nargin < 1
                color_map = plasma();
                grid_color = [ 1 1 1 ];
            end
            
            obj.color_map = color_map;
            obj.grid_color = grid_color;
            
        end
        
        
        function create_axes( ...
                obj, ...
                figure_handle, ...
                button_down_Callback, ...
                phi_grid, ...
                theta_grid ...
                )
            
            set( 0, 'CurrentFigure', figure_handle );
            obj.axes_handle = obj.build_axes( figure_handle );
            
            obj.set_axes_button_down_Callback( button_down_Callback )
            
            obj.surface_plot_handles = obj.create_plot_handle( @(axhm, values, update_color_bar, color_bar_range)obj.create_surface_plot( axhm, phi_grid, theta_grid, values, update_color_bar, color_bar_range ) );
            obj.picked_point_plot_handles = obj.create_plot_handle( @(axhm, point)obj.create_picked_point_plot( axhm, point ) );
            
        end
        
        
        function pos = get_axes_position( obj )
            
            pos = obj.axes_handle.Position;
            
        end
        
        
        function set_axes_position( obj, pos )
            
            obj.axes_handle.Position = pos;
            
        end
        
        
        function update_surface_plots( obj, values, do_update_color_bar, color_bar_range )
            
            obj.update_plot_handles( obj.surface_plot_handles, values, do_update_color_bar, color_bar_range );
            
        end
        
        
        function update_picked_point( obj, values )
            
            obj.update_plot_handles( obj.picked_point_plot_handles, values );
            
        end
        
        
        function axes_h = get_axes( obj )
            
            axes_h = obj.axes_handle;
            
        end
        
        
    end
    
    
    properties ( Access = private )
        
        color_map
        grid_color
        axes_handle
        
        surface_plot_handles
        picked_point_plot_handles
        
    end
    
    
    methods ( Access = private )
        
        function set_axes_button_down_Callback( obj, button_down_Callback )
            
            assert( ~isempty( obj.axes_handle ) );
            obj.axes_handle.ButtonDownFcn = button_down_Callback;
            
        end
        
        
        function update_plot_handles( obj, handle, values, do_update_color_bar, color_bar_range )
            
            if nargin < 4
                handle.update( obj.axes_handle, values );
            else
                handle.update( obj.axes_handle, values, do_update_color_bar, color_bar_range );
            end
            
            
        end
        
        
        function remove_plot_handles( obj, handle )
            
            handle.remove();
            
        end
        
        
        function handle = create_plot_handle( obj, plot_function )
            
            handle = AxesPlotHandle( plot_function );
            
        end
        
        
        function handle = create_surface_plot( obj, axhm, phi_grid, theta_grid, values, do_update_color_bar, color_bar_range )
            
            axes( axhm );
            handle = surfacem( theta_grid, phi_grid, rescale( values, color_bar_range.min, color_bar_range.max ) );
            handle.HitTest = 'off';
            uistack( handle, 'bottom' );
            if do_update_color_bar
                obj.update_colorbar( color_bar_range );
            end
            
        end
        
        
        function update_colorbar( obj, color_bar_range )
            
            colormap( obj.color_map );
            colorbar_handle = obj.add_colorbar( color_bar_range );
            obj.reposition_colorbar( colorbar_handle );
            
        end
        
        
        function colorbar_handle = add_colorbar( obj, color_bar_range )
            
            axh = obj.get_axes();
            original_axes_size = axh.Position;
            
            colorbar( axh, 'off' );
            colorbar_handle = colorbar( axh );
            caxis( [ color_bar_range.min color_bar_range.max ] );
            clim = colorbar_handle.Limits;
            COLORBAR_TICK_COUNT = 11;
            colorbar_handle.Ticks = linspace( clim( 1 ), clim( 2 ), COLORBAR_TICK_COUNT );
            
            caxis( axh, 'manual' );
            
            axh.Position = original_axes_size;
                
        end
        
        
        function handle = build_axes( obj, figure_handle )
            
            handle = axesm( ...
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
                'gcolor', obj.grid_color, ...
                'fontcolor', obj.grid_color ...
                );
            
            axis( handle, 'tight' );
            dims = figure_handle.InnerPosition( 3 : 4 );
            ax_dims = dims * 0.70;
            excess = ( dims - ax_dims ) ./ 2;
            handle.Units = 'pixels';
            handle.Position = [ excess ax_dims ];
            x_adjust = round( 75 / 2 );
            y_adjust = -round( 23 / 2 );
            handle.Position( 1 : 2 ) = handle.Position( 1 : 2 ) - [ x_adjust y_adjust ];
            
            handle.ButtonDownFcn = @obj.ui_axes_button_down_Callback;
            handle.Color = 'none';
            handle.XColor = 'none';
            handle.YColor = 'none';
            
            ch = handle.Children;
            for i = 1 : numel( ch )
                
                ch( i ).HitTest = 'off';
                
            end
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function handle = create_picked_point_plot( axhm, decisions )
            
            handle = add_point_plot( axhm, decisions );
            handle.LineStyle = 'none';
            handle.Marker = 'o';
            handle.MarkerSize = 6;
            handle.MarkerEdgeColor = 'k';
            handle.MarkerFaceColor = 'b';
            handle.HitTest = 'off';
            
        end
        
        
        function reposition_colorbar( handle )
            
            pos = handle.Position;
            new_pos = pos;
            SCALING_FACTOR = 0.8;
            new_pos( 4 ) = pos( 4 ) * SCALING_FACTOR;
            new_pos( 2 ) = pos( 2 ) + ( pos( 4 ) - new_pos( 4 ) ) / 2;
            handle.Position = new_pos;
            
        end
        
    end
    
end

