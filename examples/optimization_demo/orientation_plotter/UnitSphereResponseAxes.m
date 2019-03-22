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
            obj.left_axes_h = obj.build_axes( figure_handle );
            
            obj.set_axes_button_down_Callback( button_down_Callback )
            
            obj.surface_plot_handles = obj.create_plot_handle( @(values, update_color_bar, color_bar_range)obj.create_surface_plot( phi_grid, theta_grid, values, update_color_bar, color_bar_range ) );
            [ PHI_INDEX, THETA_INDEX ] = unit_sphere_plot_indices();
            obj.minimum_plot_handles = obj.create_plot_handle( @(point)obj.create_minimum_plot( PHI_INDEX, THETA_INDEX, point ) );
            obj.pareto_front_plot_handles = obj.create_plot_handle( @(points)obj.create_pareto_front_plot( PHI_INDEX, THETA_INDEX, points ) );
            obj.picked_point_plot_handles = obj.create_plot_handle( @(point)obj.create_picked_point_plot( PHI_INDEX, THETA_INDEX, point ) );
            
        end
        
        
        function pos = get_axes_position( obj )
            
            pos = obj.left_axes_h.Position;
            
        end
        
        
        function set_axes_position( obj, pos )
            
            obj.left_axes_h.Position = pos;
            
        end
        
        
        function update_surface_plots( obj, values, do_update_color_bar, color_bar_range )
            
            obj.update_plot_handles( obj.surface_plot_handles, values, do_update_color_bar, color_bar_range );
            
        end
        
        
        function update_minimum( obj, point )
            
            obj.update_plot_handles( obj.minimum_plot_handles, point );
            
        end
        
        
        function remove_minimum( obj )
            
            obj.remove_plot_handles( obj.minimum_plot_handles );
            
        end
        
        
        function update_pareto_fronts( obj, values )
            
            obj.update_plot_handles( obj.pareto_front_plot_handles, values );
            
        end
        
        
        function remove_pareto_fronts( obj )
            
            obj.remove_plot_handles( obj.pareto_front_plot_handles );
            
        end
        
        
        function update_picked_point( obj, values )
            
            obj.update_plot_handles( obj.picked_point_plot_handles, values );
            
        end
        
        
    end
    
    
    properties ( Access = private )
        
        color_map
        grid_color
        left_axes_h
        
        surface_plot_handles
        minimum_plot_handles
        pareto_front_plot_handles
        picked_point_plot_handles
        
    end
    
    
    methods ( Access = private )
        
        function set_axes_button_down_Callback( obj, button_down_Callback )
            
            assert( ~isempty( obj.left_axes_h ) );
            obj.left_axes_h.ButtonDownFcn = button_down_Callback;
            
        end
        
        
        function update_plot_handles( obj, handle, values, do_update_color_bar, color_bar_range )
            
            if nargin < 4
                handle.update( values );
            else
                handle.update( values, do_update_color_bar, color_bar_range );
            end
            
            
        end
        
        
        function remove_plot_handles( obj, handle )
            
            handle.remove();
            
        end
        
        
        function handle = create_plot_handle( obj, plot_function )
            
            handle = AxesPlotHandle( obj.get_axes(), plot_function );
            
        end
        
        
        function handle = create_surface_plot( obj, phi_grid, theta_grid, values, do_update_color_bar, color_bar_range )
            
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
            
            axes_handle = obj.get_axes();
            original_axes_size = axes_handle.Position;
            
            colorbar( axes_handle, 'off' );
            colorbar_handle = colorbar( axes_handle );
            caxis( [ color_bar_range.min color_bar_range.max ] );
            clim = colorbar_handle.Limits;
            COLORBAR_TICK_COUNT = 11;
            colorbar_handle.Ticks = linspace( clim( 1 ), clim( 2 ), COLORBAR_TICK_COUNT );
            
            caxis( axes_handle, 'manual' );
            
            axes_handle.Position = original_axes_size;
                
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
        
        
        function axes_h = get_axes( obj )
            
            axes_h = obj.left_axes_h;
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function handle = create_minimum_plot( phi_index, theta_index, decisions )
            
            handle = UnitSphereResponseAxes.add_point_plot( phi_index, theta_index, decisions );
            handle.LineStyle = 'none';
            handle.Marker = 'o';
            handle.MarkerSize = 6;
            handle.MarkerEdgeColor = 'k';
            handle.MarkerFaceColor = 'g';
            handle.HitTest = 'off';
            
        end
        
        
        function handle = create_pareto_front_plot( phi_index, theta_index, decisions )
            
            handle = UnitSphereResponseAxes.add_point_plot( phi_index, theta_index, decisions );
            handle.LineStyle = 'none';
            handle.Marker = 'o';
            handle.MarkerSize = 4;
            handle.MarkerEdgeColor = 'k';
            handle.MarkerFaceColor = 'r';
            handle.HitTest = 'off';
            
        end
        
        
        function handle = create_picked_point_plot( phi_index, theta_index, decisions )
            
            handle = UnitSphereResponseAxes.add_point_plot( phi_index, theta_index, decisions );
            handle.LineStyle = 'none';
            handle.Marker = 'o';
            handle.MarkerSize = 6;
            handle.MarkerEdgeColor = 'k';
            handle.MarkerFaceColor = 'b';
            handle.HitTest = 'off';
            
        end
        
        
        function handle = add_point_plot( phi_index, theta_index, points )
            
            handle = plotm( points( :, theta_index ), points( :, phi_index ) );
            
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

