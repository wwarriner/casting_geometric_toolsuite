classdef (Sealed) UnitSphereResponseAxes < handle
    
    methods ( Access = public )
        
        
        function obj = UnitSphereResponseAxes( color_map )
            
            if nargin < 1
                color_map = plasma();
            end
            
            obj.color_map = color_map;
            
        end
        
        
        function create_axes( ...
                obj, ...
                figure_handle, ...
                button_down_Callback, ...
                phi_grid, ...
                theta_grid ...
                )
            
            set( 0, 'CurrentFigure', figure_handle );
            obj.left_axes_h = obj.build_axes( obj.LEFT_SIDE );
            obj.right_axes_h = obj.build_axes( obj.RIGHT_SIDE );
            
            obj.set_axes_button_down_Callback( button_down_Callback )
            
            obj.surface_plot_handles = obj.create_plot_handles( @(side,values)obj.create_surface_plot( side, phi_grid, theta_grid, values ) );
            [ PHI_INDEX, THETA_INDEX ] = unit_sphere_plot_indices();
            obj.minimum_plot_handles = obj.create_plot_handles( @(side,point)obj.create_minimum_plot( PHI_INDEX, THETA_INDEX, point ) );
            obj.pareto_front_plot_handles = obj.create_plot_handles( @(side,points)obj.create_pareto_front_plot( PHI_INDEX, THETA_INDEX, points ) );
            obj.picked_point_plot_handles = obj.create_plot_handles( @(side,point)obj.create_picked_point_plot( PHI_INDEX, THETA_INDEX, point ) );
            
        end
        
        
        function update_surface_plots( obj, values )
            
            obj.update_plot_handles( obj.surface_plot_handles, values );
            
        end
        
        
        function update_minima( obj, values )
            
            obj.update_plot_handles( obj.minimum_plot_handles, values );
            
        end
        
        
        function remove_minima( obj )
            
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
        left_axes_h
        right_axes_h
        
        surface_plot_handles
        minimum_plot_handles
        pareto_front_plot_handles
        picked_point_plot_handles
        
    end
    
    
    properties ( Access = private, Constant )
        
        LEFT_SIDE = 1;
        RIGHT_SIDE = 2;
        
    end
    
    
    methods ( Access = private )
        
        function set_axes_button_down_Callback( obj, button_down_Callback )
            
            assert( ~isempty( obj.left_axes_h ) );
            assert( ~isempty( obj.right_axes_h ) );
            
            obj.left_axes_h.ButtonDownFcn = button_down_Callback;
            obj.right_axes_h.ButtonDownFcn = button_down_Callback;
            
        end
        
        
        function update_plot_handles( obj, handles, values )
            
            update_fn = @(side)handles( side ).update( values );
            obj.update_both_sides( update_fn );
            
        end
        
        
        function remove_plot_handles( obj, handles )
            
            update_fn = @(side)handles( side ).remove();
            obj.update_both_sides( update_fn );
            
        end
        
        
        function handles = create_plot_handles( obj, plot_function )
            
            handles = [ ...
                AxesPlotHandle( obj.get_axes( obj.LEFT_SIDE ), @(x)plot_function( obj.LEFT_SIDE, x ) ) ...
                AxesPlotHandle( obj.get_axes( obj.RIGHT_SIDE ), @(x)plot_function( obj.RIGHT_SIDE, x ) ) ...
                ];
            
        end
        
        
        function handle = create_surface_plot( obj, side, phi_grid, theta_grid, values )
            
            handle = surfacem( theta_grid, phi_grid, values );
            handle.HitTest = 'off';
            uistack( handle, 'bottom' );
            obj.update_colorbar( side );
            
        end
        
        
        function update_colorbar( obj, side )
            
            colormap( obj.color_map );
            if side == obj.LEFT_SIDE
                colorbar_handle = obj.add_colorbar( side );
                obj.rescale_colorbar( colorbar_handle );
            end
            
        end
        
        
        function colorbar_handle = add_colorbar( obj, side )
            
            axes_handle = obj.get_axes( side );
            original_axes_size = axes_handle.Position;
            
            colorbar( axes_handle, 'off' );
            colorbar_handle = colorbar( axes_handle );
            clim = colorbar_handle.Limits;
            COLORBAR_TICK_COUNT = 11;
            colorbar_handle.Ticks = linspace( clim( 1 ), clim( 2 ), COLORBAR_TICK_COUNT );
            
            axes_handle.Position = original_axes_size;
                
        end
        
        
        function handle = build_axes( obj, side )
            
            switch side
                case obj.LEFT_SIDE
                    subplot_position = 1;
                    polar_azimuth_deg = 0;
                case obj.RIGHT_SIDE
                    subplot_position = 2;
                    polar_azimuth_deg = 180;
                otherwise
                    assert( false )
            end
            
            subtightplot( 1, 2, subplot_position, 0.08 );
            handle = axesm( ...
                'breusing', ...
                'frame', 'on', ...
                'grid', 'on', ...
                'origin', newpole( 90, polar_azimuth_deg ), ...
                'glinewidth', 1, ...
                'mlinelocation', 30, ...
                'mlabellocation', 30, ...
                'mlabelparallel', 15, ...
                'meridianlabel', 'on', ...
                'plinelocation', 30, ...
                'plabellocation', 30, ...
                'plabelmeridian', polar_azimuth_deg, ...
                'parallellabel', 'on', ...
                'labelformat', 'signed', ...
                'gcolor', 'w', ...
                'fontcolor', 'w' ...
                );
            handle.ButtonDownFcn = @obj.ui_axes_button_down_Callback;
            handle.Color = 'none';
            handle.XColor = 'none';
            handle.YColor = 'none';
            
            ch = handle.Children;
            for i = 1 : numel( ch )
                
                ch( i ).HitTest = 'off';
                
            end
            
        end
        
        
        function update_both_sides( obj, update_function )
            
            obj.update_side( obj.LEFT_SIDE, update_function );
            obj.update_side( obj.RIGHT_SIDE, update_function );
            
        end
        
        
        function update_side( obj, side, update_function )
            
            obj.select_axes( side );
            update_function( side );
            
        end
        
        
        function axes_h = select_axes( obj, side )
            
            axes_h = obj.get_axes( side );
            axes( axes_h );
            
        end
        
        
        function axes_h = get_axes( obj, side )
            
            switch side
                case obj.LEFT_SIDE
                    axes_h = obj.left_axes_h;
                case obj.RIGHT_SIDE
                    axes_h = obj.right_axes_h;
                otherwise
                    assert( false );
            end
            
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
        
        
        function rescale_colorbar( handle )
            
            pos = handle.Position;
            new_pos = pos;
            SCALING_FACTOR = 0.8;
            new_pos( 4 ) = pos( 4 ) * SCALING_FACTOR;
            new_pos( 2 ) = pos( 2 ) + ( pos( 4 ) - new_pos( 4 ) ) / 2;
            handle.Position = new_pos;
            
        end
        
    end
    
end

