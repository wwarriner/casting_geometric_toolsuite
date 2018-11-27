classdef (Sealed) UnitSphereResponseAxes < handle
    
    methods ( Access = public )
        
        
        function obj = UnitSphereResponseAxes( color_map )
            
            if nargin < 1
                color_map = plasma();
            end
            
            obj.color_map = color_map;
            
        end
        
        
        function create_axes( obj, figure_handle )
            
            set( 0, 'CurrentFigure', figure_handle );
            obj.build_axes( obj.LEFT_SIDE );
            obj.build_axes( obj.RIGHT_SIDE );
            
        end
        
        
        function update_surface_plots( obj, phi_grid, theta_grid, objective_values )
            
            obj.update_both_sides( @(side)obj.update_surface_plot( side, phi_grid, theta_grid, objective_values ) );
            
        end
        
        
        function update_minima( obj, minima_decisions )
            
            obj.update_both_sides( @(side)obj.update_minimum( side, minima_decisions ) );
            
        end
        
        
        function remove_minima( obj )
            
            obj.update_both_sides( @(side)obj.remove_minimum( side ) );
            
        end
        
        
        function update_pareto_fronts( obj, pareto_front_decisions )
            
            obj.update_both_sides( @(side)obj.update_pareto_front( side, pareto_front_decisions ) );
            
        end
        
        
        function remove_pareto_fronts( obj )
            
            obj.update_both_sides( @(side)obj.remove_pareto_front( side ) );
            
        end
        
        
        function set_axes_button_down_Callback( obj, callback )
            
            assert( ~isempty( obj.left_axes_h ) );
            assert( ~isempty( obj.right_axes_h ) );
            
            obj.left_axes_h.ButtonDownFcn = callback;
            obj.right_axes_h.ButtonDownFcn = callback;
            
        end
        
        
    end
    
    
    properties ( Access = private )
        
        color_map
        left_axes_h
        right_axes_h
        
    end
    
    
    properties ( Access = private, Constant )
        
        LEFT_SIDE = 1;
        RIGHT_SIDE = 2;
        
    end
    
    
    methods ( Access = private )
        
        
        function update_surface_plot( obj, side, phi_grid, theta_grid, objective_values )
            
            obj.update_patch( side, phi_grid, theta_grid, objective_values );
            obj.update_colorbar( side );
            
        end
        
        
        function build_axes( obj, side )
            
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
            axes_h = axesm( ...
                'breusing', ...
                'grid', 'on', ...
                'gcolor', 'w', ...
                'glinewidth', 1, ...
                'frame', 'on', ...
                'labelformat', 'signed', ...
                'mlinelocation', 30, ...
                'mlabellocation', 30, ...
                'mlabelparallel', 15, ...
                'meridianlabel', 'on', ...
                'plinelocation', 30, ...
                'plabellocation', 30, ...
                'plabelmeridian', polar_azimuth_deg, ...
                'parallellabel', 'on', ...
                'fontcolor', 'w', ...
                'origin', newpole( 90, polar_azimuth_deg ) ...
                );
            axes_h.ButtonDownFcn = @obj.ui_axes_button_down_Callback;
            axes_h.XColor = 'w';
            axes_h.YColor = 'w';
            
            ch = axes_h.Children;
            for i = 1 : numel( ch )
                
                ch( i ).HitTest = 'off';
                
            end
            
            obj.set_axes( axes_h, side );
            
        end
        
        
        function update_patch( obj, side, phi_grid, theta_grid, values )
            
            obj.remove_patch( side );
            obj.plot_patch( side, phi_grid, theta_grid, values );
            
        end
        
        
        function plot_patch( obj, side, phi_grid, theta_grid, values )
            
            plot_h = obj.add_surface_plot( obj.get_patch_tag( side ), phi_grid, theta_grid, values );
            plot_h.HitTest = 'off';
            uistack( plot_h, 'bottom' );
            
        end
        
        
        function remove_patch( obj, side )
            
            obj.remove_existing_tag( side, obj.get_patch_tag( side ) );
            
        end
        
        
        function tag = get_patch_tag( obj, side )
            
            tag = obj.generate_tag( 'patch', side );
            
        end
        
        
        function update_minimum( obj, side, decisions )
            
            obj.remove_minimum( side );
            obj.plot_minimum( side, decisions );
            
        end
        
        
        function plot_minimum( obj, side, decisions )
            
            plot_h = obj.add_point_plot( obj.get_minimum_tag( side ), decisions );
            plot_h.LineStyle = 'none';
            plot_h.Marker = 'o';
            plot_h.MarkerSize = 6;
            plot_h.MarkerEdgeColor = 'k';
            plot_h.MarkerFaceColor = 'g';
            plot_h.HitTest = 'off';
            
        end
        
        
        function remove_minimum( obj, side )
            
            obj.remove_existing_tag( side, obj.get_minimum_tag( side ) )
            
        end
        
        
        function tag = get_minimum_tag( obj, side )
            
            tag = obj.generate_tag( 'minimum', side );
            
        end
        
        
        function update_pareto_front( obj, side, decisions )
            
            obj.remove_pareto_front( side );
            obj.plot_pareto_front( side, decisions );
            
        end
        
        
        function plot_pareto_front( obj, side, decisions )
            
            plot_h = obj.add_point_plot( obj.get_pareto_front_tag( side ), decisions );
            plot_h.LineStyle = 'none';
            plot_h.Marker = 'o';
            plot_h.MarkerSize = 4;
            plot_h.MarkerEdgeColor = 'k';
            plot_h.MarkerFaceColor = 'r';
            plot_h.HitTest = 'off';
            
        end
        
        
        function remove_pareto_front( obj, side )
            
            obj.remove_existing_tag( side, obj.get_pareto_front_tag( side ) )
            
        end
        
        
        function tag = get_pareto_front_tag( obj, side )
            
            tag = obj.generate_tag( 'pareto_front', side );
            
        end
        
        
        function tag = generate_tag( obj, side, prefix )
            
            tag = sprintf( '%s_%i', prefix, side );
            
        end
        
        
        function remove_existing_tag( obj, side, tag )
            
            handle = findobj( obj.get_axes( side ), 'tag', tag );
            if ~isempty( handle )
                delete( handle );
            end
            
        end
        
        
        function handle = add_surface_plot( obj, tag, phi_grid, theta_grid, values )
            
            handle = surfacem( theta_grid, phi_grid, values );
            handle.Tag = tag;
            
        end
        
        
        function handle = add_point_plot( obj, tag, points )
            
            [ PHI_INDEX, THETA_INDEX ] = unit_sphere_plot_indices();
            handle = plotm( points( :, THETA_INDEX ), points( :, PHI_INDEX ) );
            handle.Tag = tag;
            
        end
        
        
        function update_colorbar( obj, side )
            
            colormap( obj.get_axes( side ), obj.color_map );
            if side == obj.LEFT_SIDE
                axes_h = obj.get_axes( side );
                original_axes_size = axes_h.Position;
                colorbar( axes_h, 'off' );
                cbar = colorbar( axes_h );
                clim = cbar.Limits;
                COLORBAR_TICK_COUNT = 11;
                cbar.Ticks = linspace( clim( 1 ), clim( 2 ), COLORBAR_TICK_COUNT );
                axes_h.Position = original_axes_size;
                pos = cbar.Position;
                new_pos = pos;
                SCALING_FACTOR = 0.8;
                new_pos( 4 ) = pos( 4 ) * SCALING_FACTOR;
                new_pos( 2 ) = pos( 2 ) + ( pos( 4 ) - new_pos( 4 ) ) / 2;
                cbar.Position = new_pos;
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
        
        
        function set_axes( obj, axes_h, side )
            
            switch side
                case obj.LEFT_SIDE
                    obj.left_axes_h = axes_h;
                case obj.RIGHT_SIDE
                    obj.right_axes_h = axes_h;
                otherwise
                    assert( false );
            end
            
        end
        
    end
    
end

