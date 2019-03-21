classdef (Sealed) UnitSphereResponsePlot < handle
    
    methods ( Access = public )
        
        function obj = UnitSphereResponsePlot( ...
                unit_sphere_response_data, ...
                unit_sphere_response_axes, ...
                figure_resolution_px ...
                )
            
            obj.response_data = unit_sphere_response_data;
            
            widgets = UnitSphereResponsePlotWidgets( figure_resolution_px );
            obj.figure_h = obj.create_base_figure( ...
                widgets, ...
                obj.response_data.get_name(), ...
                obj.response_data.get_all_display_titles() ...
                );
            
            obj.response_axes = unit_sphere_response_axes;
            [ phi_grid, theta_grid ] = obj.response_data.get_grid_in_degrees();
            obj.response_axes.create_axes( ...
                obj.figure_h, ...
                @obj.ui_axes_button_down_Callback, ...
                phi_grid, ...
                theta_grid ...
                );
            pos = obj.response_axes.get_axes_position();
            obj.response_axes.set_axes_position( widgets.adjust_axes_position( pos ) );
            obj.last_picked_decisions = [ 0 0 ];
            
            obj.constrain_quantile_value();
            obj.constrain_threshold_value();
            obj.update_surface_plots( obj.UPDATE_COLOR_BAR );
            obj.update_picked_point();
                        
        end
        
        
        function set_background_color( obj, bg_color )
            
            obj.figure_h.Color = bg_color;
            obj.static_text_h.BackgroundColor = bg_color;
            obj.threshold_button_group_h.BackgroundColor = bg_color;
            for i = 1 : numel( obj.threshold_button_group_h.Children )
                obj.threshold_button_group_h.Children( i ).BackgroundColor = bg_color;
            end
            obj.minima_checkbox_h.BackgroundColor = bg_color;
            obj.pareto_front_checkbox_h.BackgroundColor = bg_color;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        response_data
        
        response_axes
        last_picked_decisions
        
        figure_h
        
        static_text_h
        
        listbox_h
        old_listbox_value
        
        visualize_button_h
        
        threshold_button_group_h
        
        quantile_edit_text_h
        old_quantile_value
        
        threshold_edit_text_h
        old_threshold_value
        
        minima_checkbox_h
        
        pareto_front_checkbox_h
        
    end
    
    
    properties ( Access = private, Constant )
        
        QUANTILE_SELECTED = 'quantile';
        VALUE_SELECTED = 'value';
        NONE_SELECTED = 'none';
        
        QUANTILE_MIN = 0.0;
        QUANTILE_MAX = 1.0;
        INITIAL_QUANTILE_VALUE = 0.01;
        
        THRESHOLD_MIN = 0.0;
        THRESHOLD_MAX = 1.0;
        INITIAL_THRESHOLD_VALUE = 0.5;
        
        MINIMA_OFF = false;
        MINIMA_ON = true;
        
        PARETO_FRONT_OFF = false;
        PARETO_FRONT_ON = true;
        
        UPDATE_COLOR_BAR = true;
        
    end
    
    
    methods ( Access = private )
        
        function figure_h = create_base_figure( obj, ...
                widgets, ...
                component_name, ...
                titles ...
                )
            
            figure_h = widgets.create_figure( component_name );
            
            obj.static_text_h = widgets.add_point_information_text( figure_h );
            
            obj.listbox_h = widgets.add_objective_selection_listbox( ...
                figure_h, ...
                titles, ...
                @obj.ui_objective_selection_listbox_Callback ...
                );
            obj.old_listbox_value = obj.get_objective_index();
            
            obj.visualize_button_h = widgets.add_visualize_button( ...
                figure_h, ...
                @obj.ui_visualize_button_Callback ...
                );
            
            [ obj.threshold_button_group_h, obj.quantile_edit_text_h, obj.threshold_edit_text_h ] = ...
                widgets.add_threshold_widgets( ...
                { obj.QUANTILE_SELECTED, obj.VALUE_SELECTED, obj.NONE_SELECTED }, ...
                [ obj.INITIAL_QUANTILE_VALUE, obj.INITIAL_THRESHOLD_VALUE ], ...
                figure_h, ...
                @obj.ui_threshold_selection_Callback, ...
                { @obj.ui_quantile_value_edit_text_Callback, @obj.ui_threshold_value_edit_text_Callback }, ...
                { @(~,~,~,~)drawnow(), @(~,~,~,~)drawnow() } ...
                );
            obj.old_quantile_value = obj.get_quantile_value();
            obj.old_threshold_value = obj.get_threshold_value();
            
            [ obj.minima_checkbox_h, obj.pareto_front_checkbox_h ] = ...
                widgets.add_point_plot_widgets( ...
                figure_h, ...
                @obj.ui_minima_checkbox_Callback, ...
                @obj.ui_pareto_front_checkbox_Callback ...
                );
            obj.minima_checkbox_h.Min = obj.MINIMA_OFF;
            obj.minima_checkbox_h.Max = obj.MINIMA_ON;
            obj.minima_checkbox_h.Value = obj.MINIMA_OFF;
            obj.pareto_front_checkbox_h.Min = obj.PARETO_FRONT_OFF;
            obj.pareto_front_checkbox_h.Max = obj.PARETO_FRONT_ON;
            obj.pareto_front_checkbox_h.Value = obj.PARETO_FRONT_OFF;
            
        end
        
        
        function ui_objective_selection_listbox_Callback( obj, ~, ~, ~ )
            
            if obj.get_objective_index() ~= obj.old_listbox_value
                obj.update_surface_plots( obj.UPDATE_COLOR_BAR );
                obj.update_minima();
                obj.update_picked_point();
                obj.update_old_listbox_value();
                obj.constrain_threshold_value();
            end
            drawnow();
            
        end
        
        
        function ui_threshold_selection_Callback( obj, ~, ~, ~ )
            
            obj.update_surface_plots();
            drawnow();
            
        end
        
        
        function ui_quantile_value_edit_text_Callback( obj, ~, ~, ~ )
            
            obj.constrain_quantile_value();
            if obj.get_quantile_value() ~= obj.old_quantile_value
                obj.set_threshold_state( obj.QUANTILE_SELECTED );
                obj.update_surface_plots();
                obj.update_old_quantile_value();
            end
            drawnow();
            
        end
        
        
        function ui_threshold_value_edit_text_Callback( obj, ~, ~, ~ )
            
            obj.constrain_threshold_value();
            if obj.get_threshold_value() ~= obj.old_threshold_value
                obj.set_threshold_state( obj.VALUE_SELECTED );
                obj.update_surface_plots();
                obj.update_old_threshold_value();
            end
            drawnow();
            
        end
        
        
        function constrain_quantile_value( obj )
            
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
        
        
        function constrain_threshold_value( obj )
            
            value = obj.get_threshold_value();
            
            if isnan( value )
                obj.set_threshold_value( obj.old_threshold_value );
            end
            
            values = obj.get_value_range();
            if values.max < value
                obj.set_threshold_value( values.max );
            elseif value < values.min
                obj.set_threshold_value( values.min );
            end
            
        end
        
        
        function ui_minima_checkbox_Callback( obj, ~, ~, ~ )
            
            obj.update_minima();
            drawnow();
            
        end
        
        
        function update_minima( obj )
            
            switch obj.minima_checkbox_h.Value
                case obj.MINIMA_OFF
                    obj.response_axes.remove_minima();
                case obj.MINIMA_ON
                    obj.response_axes.update_minima( obj.get_minima_decisions() );
                otherwise
                    assert( false );
            end
            
        end
        
        
        function decisions = get_minima_decisions( obj )
            
            decisions = obj.response_data.get_minima_decisions_in_degrees( ...
                obj.get_objective_index() ...
                );
            
        end
        
        
        function ui_pareto_front_checkbox_Callback( obj, handle, ~, ~ )
            
            switch handle.Value
                case obj.PARETO_FRONT_OFF
                    obj.response_axes.remove_pareto_fronts();
                case obj.PARETO_FRONT_ON
                    obj.response_axes.update_pareto_fronts( ...
                        obj.get_pareto_front_decisions() ...
                        );
                otherwise
                    assert( false );
            end
            obj.update_minima();
            drawnow();
            
        end
        
        
        function decisions = get_pareto_front_decisions( obj )
            
            decisions = obj.response_data.get_pareto_front_decisions_in_degrees();
            
        end
        
        
        function ui_visualize_button_Callback( obj, ~, ~, ~ )
            
            % TODO lock out other callbacks while running
            % TODO feeder intersection with undercuts means inaccessible
            
            decisions = obj.last_picked_decisions;
            
            fh = figure();
            fh.Name = sprintf( ...
                'Visualization with @X: %.2f and @Y: %.2f', ...
                rad2deg( decisions( 1 ) ), ...
                rad2deg( decisions( 2 ) ) ...
                );
            fh.NumberTitle = 'off';
            fh.MenuBar = 'none';
            fh.ToolBar = 'none';
            fh.DockControls = 'off';
            fh.Resize = 'off';
            cameratoolbar( fh, 'show' );
            
            axh = axes( fh );
            axh.Color = 'none';
            hold( axh, 'on' );
            rotated_component_fv = obj.response_data.get_rotated_component_fv( obj.last_picked_decisions );
            rch = patch( axh, rotated_component_fv, 'SpecularStrength', 0.0 );
            rch.FaceColor = [ 0.9 0.9 0.9 ];
            rch.EdgeColor = 'none';
            
            rotated_feeder_fvs = obj.response_data.get_rotated_feeder_fvs( obj.last_picked_decisions );
            for i = 1 : numel( rotated_feeder_fvs )
                
                rfh = patch( axh, rotated_feeder_fvs{ i }, 'SpecularStrength', 0.0 );
                rfh.FaceColor = [ 0.75 0.0 0.0 ];
                rfh.FaceAlpha = 0.5;
                rfh.EdgeColor = 'none';
                
            end
            
            all_fvs = [ rotated_feeder_fvs; rotated_component_fv ];
            min_point = [ 0 0 0 ];
            max_point = [ 0 0 0 ];
            for i = 1 : numel( all_fvs )
                
                curr_min_point = min( all_fvs{ i }.vertices );
                min_point = min( [ curr_min_point; min_point ] );
                
                curr_max_point = max( all_fvs{ i }.vertices );
                max_point = max( [ curr_max_point; max_point ] );
                
            end
            cor_point = obj.response_data.get_center_of_rotation();
            pa = PrettyAxes3D( min_point, max_point, cor_point );
            pa.draw( axh );
            bm = BasicMold( min_point, max_point, cor_point );
            bm.draw( axh );
            view( 3 );
            light( axh, 'Position', [ 0 0 -1 ] );
            light( axh, 'Position', [ 0 0 1 ] );
            
            axis( axh, 'equal', 'vis3d', 'off' );
            
            % attach observer for status updates?
            % factor out feature computation from determine_objectives in obc
            % generate desired visualization based on results table, i.e. using
            %  "process" and the appropriate visualization method
            
        end
        
        
        function ui_axes_button_down_Callback( obj, h, ~, ~ )
            
            point_values = gcpmap( h );
            phi_raw = point_values( 1, 2 );
            theta_raw = point_values( 1, 1 );
            [ phi_index, theta_index ] = ...
                obj.get_grid_indices_from_decisions( phi_raw, theta_raw );
            [ phi, theta ] = ...
                obj.response_data.get_grid_decisions_from_indices_in_radians( phi_index, theta_index );
            phi_deg = rad2deg( phi );
            theta_deg = rad2deg( theta );
            value = num2str( obj.get_objective_value( theta_index, phi_index ) );
            degrees = char( 176 );
            pattern = [ ...
                'Selected Point is @X: %.2f' degrees ...
                ', @Y: %.2f' degrees ...
                ', Value: %s' ...
                ];
            obj.static_text_h.String = sprintf( pattern, phi_deg, theta_deg, value );
            drawnow();
            obj.last_picked_decisions = [ phi theta ];
            obj.update_picked_point();
            
        end
        
        
        function update_picked_point( obj )
            
            obj.response_axes.update_picked_point( rad2deg( obj.last_picked_decisions ) );
            
        end
        
        
        function [ phi_index, theta_index ] = get_grid_indices_from_decisions( ...
                obj, ...
                phi, ...
                theta ...
                )
            
            [ phi_index, theta_index ] = ...
                obj.response_data.get_grid_indices_from_decisions( phi, theta );
            
        end
        
        
        function update_surface_plots( obj, do_update_color_bar )
            
            if nargin < 2
                do_update_color_bar = false;
            end
            objective_values = obj.get_objective_values();
            color_bar_range = [ min( objective_values, [], 'all' ) max( objective_values, [], 'all' ) ];
            obj.response_axes.update_surface_plots( obj.get_surface_plot_values(), do_update_color_bar, color_bar_range );
            
        end
        
        
        function values = get_surface_plot_values( obj )
            
            switch obj.get_threshold_state()
                case obj.QUANTILE_SELECTED
                    values = obj.get_quantile_values();
                case obj.VALUE_SELECTED
                    values = obj.get_thresholded_values();
                case obj.NONE_SELECTED
                    values = obj.get_objective_values();
                otherwise
                    assert( false );
            end
            
        end
        
        
        function state = get_threshold_state( obj )
            
            state = obj.threshold_button_group_h.SelectedObject.Tag;
            
        end
        
        
        function set_threshold_state( obj, tag )
            
            h = findobj( obj.threshold_button_group_h, 'tag', tag );
            h.Value = 1;
            
        end
        
        
        function update_old_listbox_value( obj )
            
            obj.old_listbox_value = obj.get_objective_index();
            
        end
        
        
        function update_old_quantile_value( obj )
            
            obj.old_quantile_value = obj.get_quantile_value();
            
        end
        
        
        function update_old_threshold_value( obj )
            
            obj.old_threshold_value = obj.get_threshold_value();
            
        end
        
        
        function set_quantile_value( obj, value )
            
            obj.quantile_edit_text_h.String = num2str( value );
            
        end
        
        
        function set_threshold_value( obj, value )
            
            obj.threshold_edit_text_h.String = num2str( value, '%.3g' );
            
        end
        
        
        function value = get_objective_value( obj, phi_index, theta_index )
            
            value = obj.response_data.get_objective_value( ...
                phi_index, ...
                theta_index, ...
                obj.get_objective_index() ...
                );
            
        end
        
        
        function values = get_objective_values( obj )
            
            values = obj.response_data.get_objective_values( ...
                obj.get_objective_index() ...
                );
            
        end
        
        
        function values = get_quantile_values( obj )
            
            values = obj.response_data.get_quantile_values( ...
                obj.get_quantile_value(), ...
                obj.get_objective_index() ...
                );
            values = double( values );
            
        end
        
        
        function values = get_thresholded_values( obj )
            
            values = obj.response_data.get_thresholded_values( ...
                obj.get_threshold_value(), ...
                obj.get_objective_index() ...
                );
            values = double( values );
            
        end
        
        
        function value = get_objective_index( obj )
            
            value = obj.listbox_h.Value;
            
        end
        
        
        function value = get_quantile_value( obj )
            
            value = str2double( obj.quantile_edit_text_h.String );
            
        end
        
        
        function value = get_threshold_value( obj )
            
            value = str2double( obj.threshold_edit_text_h.String );
            
        end
        
        
        function values = get_value_range( obj )
            
            values = obj.response_data.get_objective_value_range( obj.get_objective_index() );
            
        end
        
    end
    
end

