classdef (Sealed) UnitSphereResponsePlot < handle
    
    methods ( Access = public )
        
        function obj = UnitSphereResponsePlot( ...
                unit_sphere_response_data, ...
                unit_sphere_response_axes, ...
                figure_resolution_px ...
                )
            
            obj.response_data = unit_sphere_response_data;
            
            obj.figure_h = obj.create_base_figure( ...
                figure_resolution_px, ...
                obj.response_data.get_name(), ...
                obj.response_data.get_all_titles() ...
                );
            
            obj.response_axes = unit_sphere_response_axes;
            [ phi_grid, theta_grid ] = obj.response_data.get_grid_in_degrees();
            obj.response_axes.create_axes( ...
                obj.figure_h, ...
                @obj.ui_axes_button_down_Callback, ...
                phi_grid, ...
                theta_grid ...
                );
            
            obj.update_surface_plots();
            
        end
        
    end
    
    
    properties ( Access = private )
        
        response_data
        response_axes
        
        figure_h
        
        static_text_h
        
        listbox_h
        old_listbox_value
        
        visualize_button_h
        
        quantile_checkbox_h
        quantile_value_edit_text_h
        old_quantile_value
        
        minima_checkbox_h
        
        pareto_front_checkbox_h
        
    end
    
    
    properties ( Access = private, Constant )
        
        INITIAL_LISTBOX_VALUE = 1;
        
        PHI_INDEX = 1;
        THETA_INDEX = 2;
        
        QUANTILE_OFF = false;
        QUANTILE_ON = true;
        
        QUANTILE_MIN = 0.0;
        QUANTILE_MAX = 1.0;
        INITIAL_QUANTILE_VALUE = 0.01;
        
        MINIMA_OFF = false;
        MINIMA_ON = true;
        
        PARETO_FRONT_OFF = false;
        PARETO_FRONT_ON = true;
        
    end
    
    
    methods ( Access = private )
        
        
        function update_title( obj )
            
            obj.figure_h.Name = obj.get_title( obj.get_objective_index() );
            
        end
        
        
        function update_old_listbox_value( obj )
            
            obj.old_listbox_value = obj.get_objective_index();
            
        end
        
        
        function update_old_quantile_value( obj )
            
            obj.old_quantile_value = obj.get_quantile_value();
            
        end
        
        
        function set_quantile_value( obj, value )
            
            obj.quantile_value_edit_text_h.String = num2str( value );
            
        end
        
        
        function title = get_title( obj, index )
            
            title = obj.response_data.get_title( index );
            
        end
        
        
        function value = get_objective_value( obj, phi_index, theta_index )
            
            value = obj.response_data.get_objective_value( ...
                phi_index, ...
                theta_index, ...
                obj.get_objective_index() ...
                );
            
        end
        
        
        function values = get_objective_values( obj )
            
            values = obj.response_data.get_objective_values( obj.get_objective_index() );
            
        end
        
        
        function values = get_quantile_values( obj )
            
            values = obj.response_data.get_quantile_values( ...
                obj.get_quantile_value(), ...
                obj.get_objective_index() ...
                );
            values = double( values );
            
        end
        
        
        function decisions = get_minima_decisions( obj )
            
            decisions = obj.response_data.get_minima_decisions_in_degrees( obj.get_objective_index() );
            
        end
        
        
        function decisions = get_pareto_front_decisions( obj )
            
            decisions = obj.response_data.get_pareto_front_decisions_in_degrees();
            
        end
        
        
        function value = get_quantile_threshold_value( obj )
            
            value = obj.response_data.get_quantile_threshold_value( ...
                obj.get_quantile_value(), ...
                obj.get_objective_index() ...
                );
            
        end
        
        
        function [ phi_index, theta_index ] = get_grid_indices_from_decisions( obj, phi, theta )
            
            [ phi_index, theta_index ] = obj.response_data.get_grid_indices_from_decisions( phi, theta );
            
        end
        
        
        function plot_values = get_plot_values( obj )
            
            switch obj.get_quantile_state()
                case obj.QUANTILE_OFF
                    plot_values = obj.get_objective_values();
                case obj.QUANTILE_ON
                    plot_values = double( obj.get_objective_values() < obj.get_quantile_threshold_value() );
                otherwise
                    assert( false );
            end
            
        end
        
        
        function value = get_objective_index( obj )
            
            value = obj.listbox_h.Value;
            
        end
        
        
        function value = get_quantile_value( obj )
            
            value = str2double( obj.quantile_value_edit_text_h.String );
            
        end
        
        
        function state = get_quantile_state( obj )
            
            state = obj.quantile_checkbox_h.Value;
            
        end
        
        
        function state = get_minima_state( obj )
            
            state = obj.minima_checkbox_h.Value;
            
        end
        
        
        function state = get_pareto_front_state( obj )
            
            state = obj.pareto_front_checkbox_h.Value;
            
        end
        
        
        function is_changed = has_listbox_value_changed( obj )
            
            is_changed = ( obj.get_objective_index() ~= obj.old_listbox_value );
            
        end
        
        
        function is_changed = has_quantile_value_changed( obj )
            
            is_changed = ( obj.get_quantile_value() ~= obj.old_quantile_value );
            
        end
        
        
        function validate_quantile_value( obj )
            
            value = obj.get_quantile_value();
            if isnan( value )
                obj.set_quantile_value( obj.old_quantile_value );
            end
            if obj.QUANTILE_MAX < value
                obj.set_quantile_value( obj.QUANTILE_MAX );
            elseif value < obj.QUANTILE_MIN
                obj.set_quantile_value( obj.QUANTILE_MIN );
            end
            
        end
        
        
        function figure_h = create_base_figure( obj, ...
                figure_resolution_px, ...
                component_name, ...
                titles ...
                )
            
            figure_position = [ ...
                10, ...
                10, ...
                2 * figure_resolution_px + 1, ...
                make_odd( figure_resolution_px ) ...
                ];
            figure_h = figure( ...
                'name', sprintf( 'Orientation Data for %s', component_name ), ...
                'numbertitle', 'off', ...
                'color', 'w', ...
                'position', figure_position, ...
                'menubar', 'none', ...
                'toolbar', 'none', ...
                'dockcontrols', 'off', ...
                'resize', 'off' ...
                );
            
            width = 600;
            height = 23;
            vert_pad = 10;
            ui_static_text_position = [ ...
                round( ( figure_position( 3 ) - 1 ) / 2 ) - round( width / 2 ) ...
                figure_position( 4 ) - 1 - height - vert_pad ...
                width ...
                height ...
                ];
            obj.static_text_h = uicontrol( ...
                'style', 'text', ...
                'string', 'Click on the axes to get point data!', ...
                'position', ui_static_text_position, ...
                'tag', 'ui_static_text', ...
                'parent', figure_h, ...
                'backgroundcolor', 'w', ...
                'fontsize', 10 ...
                );
            uistack( obj.static_text_h, 'top' );
            
            width = 230;
            height = 23;
            vert_pad = 0;
            ui_listbox_position = [ ...
                round( ( figure_position( 3 ) - 1 ) / 2 ) - ( width / 2 ) ...
                ui_static_text_position( 2 ) - ui_static_text_position( 4 ) - vert_pad ...
                width ...
                height ...
                ];
            obj.listbox_h = uicontrol( ...
                'style', 'popupmenu', ...
                'string', titles, ...
                'value', UnitSphereResponsePlot.INITIAL_LISTBOX_VALUE, ...
                'position', ui_listbox_position, ...
                'tag', 'ui_dropdown', ...
                'parent', figure_h, ...
                'callback', @obj.ui_dropdown_Callback, ...
                'fontsize', 10 ...
                );
            uistack( obj.listbox_h, 'top' );
            obj.old_listbox_value = obj.get_objective_index();
            
            width = 80;
            height = 23;
            vert_pad = 10;
            ui_visualize_button_position = [ ...
                round( ( figure_position( 3 ) - 1 ) / 2 ) - round( width / 2 ) ...
                vert_pad ...
                width ...
                height ...
                ];
            obj.visualize_button_h = uicontrol( ...
                'style', 'pushbutton', ...
                'string', 'Visualize...', ...
                'position', ui_visualize_button_position, ...
                'tag', 'ui_visualize_button', ...
                'parent', figure_h, ...
                'callback', @obj.ui_visualize_button_Callback, ...
                'fontsize', 10 ...
                );
            uistack( obj.visualize_button_h, 'top' );
            
            checkbox_width = 120;
            height = 23;
            edit_text_width = 60;
            horz_pad = 10;
            vert_pad = 10;
            total_width = edit_text_width + horz_pad + checkbox_width;
            y_pos = ui_visualize_button_position( 4 ) + ui_visualize_button_position( 2 ) + vert_pad;
            ui_quantile_checkbox_position = [ ...
                round( ( figure_position( 3 ) - 1 ) / 2 ) - checkbox_width - round( horz_pad / 2 ) ...
                y_pos ...
                checkbox_width ...
                height ...
                ];
            obj.quantile_checkbox_h = uicontrol( ...
                'style', 'checkbox', ...
                'string', 'Show Quantile:', ...
                'position', ui_quantile_checkbox_position, ...
                'tag', 'ui_quantile_checkbox', ...
                'parent', figure_h, ...
                'callback', @obj.ui_quantile_checkbox_Callback, ...
                'min', obj.QUANTILE_OFF, ...
                'max', obj.QUANTILE_ON, ...
                'value', obj.QUANTILE_OFF, ...
                'fontsize', 10 ...
                );
            uistack( obj.quantile_checkbox_h, 'top' );
            
            ui_quantile_value_edit_text_position = [ ...
                round( ( figure_position( 3 ) - 1 ) / 2 ) + round( horz_pad / 2 ) ...
                y_pos ...
                edit_text_width ...
                height ...
                ];
            obj.quantile_value_edit_text_h = uicontrol( ...
                'style', 'edit', ...
                'string', '0.01', ...
                'position', ui_quantile_value_edit_text_position, ...
                'tag', 'ui_quantile_value_edit_text', ...
                'parent', figure_h, ...
                'callback', @obj.ui_quantile_value_edit_text_Callback, ...
                'string', num2str( obj.INITIAL_QUANTILE_VALUE ), ...
                'fontsize', 10 ...
                );
            uistack( obj.quantile_value_edit_text_h, 'top' );
            obj.old_quantile_value = obj.get_quantile_value();
            
            vert_pad = 10;
            y_pos = y_pos + height + vert_pad;
            minima_checkbox_width = 120;
            height = 23;
            pareto_front_checkbox_width = 140;
            horz_pad = 10;
            total_width = edit_text_width + horz_pad + minima_checkbox_width;
            ui_minima_checkbox_position = [ ...
                round( ( figure_position( 3 ) - 1 ) / 2 ) - checkbox_width - round( horz_pad / 2 ) ...
                y_pos ...
                minima_checkbox_width ...
                height ...
                ];
            obj.minima_checkbox_h = uicontrol( ...
                'style', 'checkbox', ...
                'string', 'Show Minima', ...
                'position', ui_minima_checkbox_position, ...
                'tag', 'ui_minima_checkbox', ...
                'parent', figure_h, ...
                'callback', @obj.ui_minima_checkbox_Callback, ...
                'min', obj.MINIMA_OFF, ...
                'max', obj.MINIMA_ON, ...
                'value', obj.MINIMA_OFF, ...
                'fontsize', 10 ...
                );
            
            ui_pareto_front_checkbox_position = [ ...
                round( ( figure_position( 3 ) - 1 ) / 2 ) + round( horz_pad / 2 ) ...
                y_pos ...
                pareto_front_checkbox_width ...
                height ...
                ];
            obj.pareto_front_checkbox_h = uicontrol( ...
                'style', 'checkbox', ...
                'string', 'Show Pareto Front', ...
                'position', ui_pareto_front_checkbox_position, ...
                'tag', 'ui_pareto_front_checkbox', ...
                'parent', figure_h, ...
                'callback', @obj.ui_pareto_front_checkbox_Callback, ...
                'min', obj.PARETO_FRONT_OFF, ...
                'max', obj.PARETO_FRONT_ON, ...
                'value', obj.PARETO_FRONT_OFF, ...
                'fontsize', 10 ...
                );
            
            
        end
        
        
        function ui_dropdown_Callback( obj, ~, ~, ~ )
            
            if obj.has_listbox_value_changed()
                obj.update_surface_plots();
                obj.update_old_listbox_value();
            end
            
        end
        
        
        function ui_quantile_checkbox_Callback( obj, ~, ~, ~ )
            
            obj.update_surface_plots();
            drawnow();
            
        end
        
        
        function ui_quantile_value_edit_text_Callback( obj, ~, ~, ~ )
            
            obj.validate_quantile_value();
            if obj.has_quantile_value_changed()
                obj.update_surface_plots();
                obj.update_old_quantile_value();
            end
            drawnow();
            
        end
        
        
        function ui_minima_checkbox_Callback( obj, ~, ~, ~ )
            
            obj.update_minima();
            drawnow();
            
        end
        
        
        function ui_pareto_front_checkbox_Callback( obj, ~, ~, ~ )
            
            obj.update_pareto_fronts();
            drawnow();
            
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
        
        
        function ui_axes_button_down_Callback( obj, h, ~, ~ )
            
            point_values = gcpmap( h );
            phi = point_values( 1, 2 );
            theta = point_values( 1, 1 );
            [ phi_index, theta_index ] = obj.get_grid_indices_from_decisions( phi, theta );
            value = num2str( obj.get_objective_value( theta_index, phi_index ) );
            degrees = char( 176 );
            pattern = [ 'Selected Point is @X: %.2f' degrees ', @Y: %.2f' degrees ', Value: %s' ];
            obj.static_text_h.String = sprintf( pattern, phi, theta, value );
            
        end
        
        
        function update_surface_plots( obj )
            
            obj.response_axes.update_surface_plots( obj.get_surface_plot_values() );
            
        end
        
        
        function update_minima( obj )
            
            switch obj.get_minima_state()
                case obj.MINIMA_OFF
                    obj.response_axes.remove_minima();
                case obj.MINIMA_ON
                    obj.response_axes.update_minima( obj.get_minima_decisions() );
                otherwise
                    assert( false );
            end
            
        end
        
        
        function update_pareto_fronts( obj )
            
            switch obj.get_pareto_front_state()
                case obj.PARETO_FRONT_OFF
                    obj.response_axes.remove_pareto_fronts();
                case obj.PARETO_FRONT_ON
                    obj.response_axes.update_pareto_fronts( obj.get_pareto_front_decisions() );
                otherwise
                    assert( false );
            end
            
        end
        
        
        function values = get_surface_plot_values( obj )
            
            switch obj.get_quantile_state()
                case obj.QUANTILE_OFF
                    values = obj.get_objective_values();
                case obj.QUANTILE_ON
                    values = obj.get_quantile_values();
                otherwise
                    assert( false );
            end
            
        end
        
    end
    
end

