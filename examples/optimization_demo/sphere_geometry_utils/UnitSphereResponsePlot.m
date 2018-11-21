classdef (Sealed) UnitSphereResponsePlot < handle
    
    methods ( Access = public )
        
        function obj = UnitSphereResponsePlot( ...
                titles, ...
                interpolants, ...
                color_map, ...
                figure_resolution_px ...
                )
            
            if nargin < 3
                color_map = plasma();
            end
            if nargin < 4
                figure_resolution_px = 600;
            end
            
            obj.titles = titles;
            obj.color_map = color_map;
            
            obj.figure_h = obj.create_base_figure( figure_resolution_px, obj.titles );
            obj.create_axes( obj.LEFT );
            obj.create_axes( obj.RIGHT );
            
            interpolant_resolution = figure_resolution_px / 2;
            [ phi_values, theta_values ] = unit_sphere_grid_values( interpolant_resolution );
            [ obj.phi_grid, obj.theta_grid ] = meshgrid( phi_values, theta_values );
            [ phi_resolution, theta_resolution ] = ...
                unit_sphere_grid_resolution( interpolant_resolution );
            count = numel( interpolants );
            obj.plot_values = nan( theta_resolution, phi_resolution, count );
            for i = 1 : count
                obj.plot_values( :, :, i ) = interpolants{ i }( ...
                    obj.phi_grid, ...
                    obj.theta_grid ...
                    );
            end
            obj.set_current_index( obj.INITIAL_VALUE );
            obj.update_figure();
            
        end
        
    end
    
    
    properties ( Access = private )
        
        figure_h
        static_text_h
        current_axes_h
        left_axes_h
        right_axes_h
        color_map
        
        current_index
        titles
        
        phi_grid
        theta_grid
        plot_values
        
    end
    
    
    methods ( Access = private )
        
        function set_current_index( obj, index )
            
            obj.current_index = index;
            
        end
        
        function update_figure( obj )
            
            obj.update_title();
            obj.update_interpolant();
            drawnow();
            
        end
        
        
        function update_title( obj )
            
            obj.figure_h.Name = obj.get_title( obj.get_current_index() );
            
        end
        
        
        function update_interpolant( obj )
            
            obj.update_axes( obj.LEFT );
            obj.update_axes( obj.RIGHT );
            
        end
        
        
        function update_axes( obj, side )
            
            % select axes
            axes_h = obj.get_axes( side );
            axes( axes_h );
            
            % update patch
            obj.update_patch( side );
            
            % update colorbar
            obj.update_colormap( side );
            if side == obj.LEFT
                original_axes_size = axes_h.Position;
                cbar = colorbar( axes_h );
                clim = cbar.Limits;
                cbar.Ticks = linspace( clim( 1 ), clim( 2 ), 11 );
                axes_h.Position = original_axes_size;
            end
            
        end
        
        
        function update_patch( obj, side )
            
            tag = sprintf( 'plot%s', side );
            existing_plot_h = findobj( obj.get_axes( side ), 'tag', tag );
            if ~isempty( existing_plot_h )
                delete( existing_plot_h );
            end
            plot_h = surfacem( ...
                rad2deg( obj.theta_grid ), ...
                rad2deg( obj.phi_grid ), ...
                obj.plot_values( :, :, obj.get_current_index() ), ...
                'tag', tag ...
                );
            plot_h.HitTest = 'off';
            uistack( plot_h, 'bottom' );
            
        end
        
        
        function update_colormap( obj, side )
            
            colormap( obj.get_axes( side ), obj.color_map );
            
        end
        
        
        function is_different = value_changed( obj, new_value )
            
            is_different = ( new_value ~= obj.current_index );
            
        end
        
        
        function value = get_current_index( obj )
            
            value = obj.current_index;
            
        end
        
        
        function title = get_title( obj, value )
            
            title = obj.titles{ value };
            
        end
        
        
        function interpolant = get_interpolant( obj, value )
            
            interpolant = obj.interpolants{ value };
            
        end
        
        
        function create_axes( obj, side )
            
            switch side
                case UnitSphereResponsePlot.LEFT
                    subplot_position = 1;
                    polar_azimuth_deg = 0;
                case UnitSphereResponsePlot.RIGHT
                    subplot_position = 2;
                    polar_azimuth_deg = 180;
                otherwise
                    assert( false )
            end
            
            subplot( 1, 2, subplot_position );
            axes_h = axesm( ...
                'breusing', ...
                'grid', 'on', ...
                'gcolor', 'w', ...
                'glinewidth', 1, ...
                'frame', 'on', ...
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
        
        
        function ui_axes_button_down_Callback( obj, h, ~, ~ )
            
            pt = gcpmap( h );
            phi = pt( 1, 2 );
            theta = pt( 1, 1 );
            
            phi_index = round( ( deg2rad( phi ) + pi ) * size( obj.phi_grid, 2 ) ./ ( 2 * pi ) );
            theta_index = round( ( deg2rad( theta ) + pi/2 ) * size( obj.theta_grid, 1 ) ./ pi );
            value = obj.plot_values( theta_index, phi_index, obj.get_current_index );
            format_spec = sig_fig_format_spec( value, 2, 4 );
            pattern = [ 'Phi: %.2f, Theta: %.2f, Value: ', format_spec ];
            obj.static_text_h.String = sprintf( ...
                pattern, ...
                phi, ...
                theta, ...
                value ...
                );
            
        end
        
        
        function set_axes( obj, axes_h, side )
            
            switch side
                case obj.LEFT
                    obj.left_axes_h = axes_h;
                case obj.RIGHT
                    obj.right_axes_h = axes_h;
                otherwise
                    assert( false );
            end
            
        end
        
        
        function axes_h = get_axes( obj, side )
            
            switch side
                case obj.LEFT
                    axes_h = obj.left_axes_h;
                case obj.RIGHT
                    axes_h = obj.right_axes_h;
                otherwise
                    assert( false );
            end
            
        end
        
        
        function figure_h = create_base_figure( obj, figure_resolution_px, titles )
            
            figure_position = [ ...
                10, ...
                10, ...
                2 * figure_resolution_px + 1, ...
                make_odd( figure_resolution_px ) ...
                ];
            figure_h = figure( ...
                'name', 'DEFAULT_NAME', ...
                'color', 'w', ...
                'position', figure_position, ...
                'menubar', 'none', ...
                'toolbar', 'none', ...
                'dockcontrols', 'off', ...
                'resize', 'off' ..., ...
                );
            %'hittest', 'off' ...
            
            width = 230;
            height = 23;
            vert_pad = 10;
            ui_dropdown_position = [ ...
                round( ( figure_position( 3 ) - 1 ) / 2 ) - ( width / 2 ) ...
                figure_position( 4 ) - 1 - height - vert_pad ...
                width ...
                height ...
                ];
            uicontrol( ...
                'style', 'popupmenu', ...
                'string', titles, ...
                'value', UnitSphereResponsePlot.INITIAL_VALUE, ...
                'position', ui_dropdown_position, ...
                'tag', 'ui_dropdown', ...
                'parent', figure_h, ...
                'callback', @obj.ui_dropdown_Callback ...
                );
            
            width = 80;
            height = 23;
            vert_pad = 10;
            ui_visualize_button_position = [ ...
                round( ( figure_position( 3 ) - 1 ) / 2 ) - ( width / 2 ) ...
                vert_pad ...
                width ...
                height ...
                ];
            uicontrol( ...
                'style', 'pushbutton', ...
                'string', 'Visualize...', ...
                'position', ui_visualize_button_position, ...
                'tag', 'ui_visualize_button', ...
                'parent', figure_h, ...
                'callback', @obj.ui_visualize_button_Callback ...
                );
            
            width = 300;
            height = 23;
            vert_pad = 10;
            ui_static_text_position = [ ...
                round( ( figure_position( 3 ) - 1 ) / 2 ) - ( width / 2 ) ...
                ui_visualize_button_position( 4 ) + ui_visualize_button_position( 2 ) + vert_pad ...
                width ...
                height ...
                ];
            obj.static_text_h = uicontrol( ...
                'style', 'text', ...
                'string', 'Click on the axes to get point data!', ...
                'position', ui_static_text_position, ...
                'tag', 'ui_static_text', ...
                'parent', figure_h ...
                );
            
        end
        
        
        function ui_dropdown_Callback( obj, h, ~, ~ )
            
            new_value = h.Value;
            if obj.value_changed( new_value )
                obj.set_current_index( new_value );
                obj.update_figure();
            end
            
        end
        
        
        function ui_visualize_button_Callback( obj, h, ~, ~ )
            
            fprintf( 'not yet implemented\n' );
            return;
            % attach options when running on hpc so we are consistent
            % attach stl when running etc etc
            % add both paths to result table
            obc = OrientationBaseCase( ...
                obj.option_path, ...
                obj.stl_path, ...
                obj.objective_variables_path ...
                );
            % attach observer for status updates?
            % factor out feature computation from determine_objectives in obc
            % generate desired visualization based on results table, i.e. using
            %  "process" and the appropriate visualization method
            % create new figure etc
            % display vis in figure
            
        end
        
    end
    
    
    properties ( Access = private, Constant )
        
        INITIAL_VALUE = 1;
        LEFT = 1;
        RIGHT = 2;
        
    end
    
end

