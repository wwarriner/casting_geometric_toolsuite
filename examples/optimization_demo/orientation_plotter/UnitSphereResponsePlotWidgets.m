classdef (Sealed) UnitSphereResponsePlotWidgets < handle
    
    methods ( Access = public )
        
        function obj = UnitSphereResponsePlotWidgets( resolution_px )
        
            obj.figure_position = obj.compute_figure_position( resolution_px );
            obj.previous_position = obj.figure_position;
            
        end
        
        
        function handle = create_figure( obj, name )
            
            handle = figure();
            handle.Name = sprintf( 'Orientation Data for %s', name );
            handle.NumberTitle = 'off';
            handle.Position = obj.figure_position;
            handle.MenuBar = 'none';
            handle.ToolBar = 'none';
            handle.DockControls = 'off';
            handle.Resize = 'off';
            movegui( handle, 'center' );
            
        end
        
        
        function pos = adjust_axes_position( obj, pos )
            
            pos = [ ...
                obj.center( pos( 3 ) ), ...
                obj.above_previous(), ...
                pos( 3 ), ...
                pos( 4 ) ...
                ];
            
        end
        
        
        function handle = add_point_information_text( obj, figure_handle )
            
            TEXT_WIDTH = 600;
            handle = uicontrol();
            handle.Style = 'text';
            handle.String = 'Click on the axes to get point data!';
            handle.FontSize = obj.FONT_SIZE;
            handle.Position = [ ...
                obj.center( TEXT_WIDTH ), ...
                obj.at_top_edge( obj.HEIGHT ) ...
                TEXT_WIDTH ...
                obj.HEIGHT ...
                ];
            handle.Parent = figure_handle;
            
            obj.previous_position = handle.Position;
            
        end
        
        
        function handle = add_objective_selection_listbox( ...
                obj, ...
                figure_handle, ...
                titles, ...
                callback ...
                )
            
            LISTBOX_WIDTH = 300;
            handle = uicontrol();
            handle.Style = 'popupmenu';
            handle.String = titles;
            handle.FontSize = obj.FONT_SIZE;
            handle.Value = obj.INITIAL_LISTBOX_VALUE;
            handle.Position = [ ...
                obj.center( LISTBOX_WIDTH ) ...
                obj.below_previous( obj.HEIGHT ) ...
                LISTBOX_WIDTH ...
                obj.HEIGHT ...
                ];
            handle.Callback = callback;
            handle.Parent = figure_handle;
            
            obj.previous_position = handle.Position;
            
        end
        
        
        function handle = add_visualize_button( obj, figure_handle, callback )
            
            BUTTON_WIDTH = 200;
            handle = uicontrol();
            handle.Style = 'pushbutton';
            handle.String = 'Visualize Picked Point...';
            handle.FontSize = obj.FONT_SIZE;
            handle.Position = [ ...
                obj.center( BUTTON_WIDTH ) ...
                obj.at_bottom_edge() ...
                BUTTON_WIDTH ...
                obj.HEIGHT ...
                ];
            handle.Callback = callback;
            handle.Parent = figure_handle;
            
            obj.previous_position = handle.Position;
            
        end
        
        
        function [ button_group_handle, quantile_edit_text_handle, value_edit_text_handle ] = add_threshold_widgets( ...
                obj, ...
                button_values, ...
                default_values, ...
                figure_handle, ...
                selection_function, ...
                edit_text_callbacks, ...
                slider_callbacks ...
                )
            
            CHECKBOX_WIDTH = 200;
            EDIT_TEXT_WIDTH = 120;
            SLIDER_WIDTH = 300;
            HALF_WIDTH = max( CHECKBOX_WIDTH, EDIT_TEXT_WIDTH );
            BUTTON_GROUP_WIDTH = HALF_WIDTH * 2 + SLIDER_WIDTH;
            BUTTON_GROUP_HEIGHT = ( obj.VERTICAL_PAD + obj.HEIGHT ) * 3 + obj.VERTICAL_PAD;
            
            LEFT = 0;
            RIGHT = HALF_WIDTH;
            SLIDER = HALF_WIDTH * 2;
            
            button_group_handle = uibuttongroup();
            button_group_handle.Units = 'pixels';
            button_group_handle.Position = [ ...
                obj.center( BUTTON_GROUP_WIDTH ) ...
                obj.above_previous() ...
                BUTTON_GROUP_WIDTH ...
                BUTTON_GROUP_HEIGHT ...
                ];
            button_group_handle.BorderType = 'none';
            button_group_handle.SelectionChangedFcn = selection_function;
            button_group_handle.Parent = figure_handle;
            
            obj.previous_position = button_group_handle.Position;
            
            none_radio_button_handle = uicontrol();
            none_radio_button_handle.Style = 'radiobutton';
            none_radio_button_handle.String = 'No Threshold';
            none_radio_button_handle.FontSize = obj.FONT_SIZE;
            none_radio_button_handle.Position = [ ...
                LEFT ...
                ( obj.VERTICAL_PAD + obj.HEIGHT ) * 2 + obj.VERTICAL_PAD ...
                CHECKBOX_WIDTH ...
                obj.HEIGHT ...
                ];
            none_radio_button_handle.Tag = button_values{ 3 };
            none_radio_button_handle.Parent = button_group_handle;
            
            value_radio_button_handle = uicontrol();
            value_radio_button_handle.Style = 'radiobutton';
            value_radio_button_handle.String = 'Value Threshold:';
            value_radio_button_handle.FontSize = obj.FONT_SIZE;
            value_radio_button_handle.Position = [ ...
                LEFT ...
                ( obj.VERTICAL_PAD + obj.HEIGHT ) * 1 + obj.VERTICAL_PAD ...
                CHECKBOX_WIDTH ...
                obj.HEIGHT ...
                ];
            value_radio_button_handle.Tag = button_values{ 2 };
            value_radio_button_handle.Parent = button_group_handle;
            
            value_default = default_values( 2 );
            
            value_edit_text_handle = uicontrol();
            value_edit_text_handle.Style = 'edit';
            value_edit_text_handle.String = value_default;
            value_edit_text_handle.FontSize = obj.FONT_SIZE;
            value_edit_text_handle.Position = [ ...
                RIGHT ...
                ( obj.VERTICAL_PAD + obj.HEIGHT ) * 1 + obj.VERTICAL_PAD ...
                EDIT_TEXT_WIDTH ...
                obj.HEIGHT ...
                ];
            value_edit_text_handle.Callback = edit_text_callbacks{ 2 };
            value_edit_text_handle.Parent = button_group_handle;
            
            value_slider_handle = uicontrol();
            value_slider_handle.Style = 'slider';
            value_slider_handle.Position = [ ...
                SLIDER ...
                ( obj.VERTICAL_PAD + obj.HEIGHT ) * 1 + obj.VERTICAL_PAD ...
                SLIDER_WIDTH ...
                obj.HEIGHT ...
                ];
            value_slider_handle.Min = value_default - 1;
            value_slider_handle.Max = value_default + 1;
            value_slider_handle.Value = value_default;
            value_slider_handle.Callback = slider_callbacks{ 2 };
            value_slider_handle.Parent = button_group_handle;
            
            quantile_radio_button_handle = uicontrol();
            quantile_radio_button_handle.Style = 'radiobutton';
            quantile_radio_button_handle.String = 'Quantile Threshold:';
            quantile_radio_button_handle.FontSize = obj.FONT_SIZE;
            quantile_radio_button_handle.Position = [ ...
                LEFT ...
                obj.VERTICAL_PAD ...
                CHECKBOX_WIDTH ...
                obj.HEIGHT ...
                ];
            quantile_radio_button_handle.Tag = button_values{ 1 };
            quantile_radio_button_handle.Parent = button_group_handle;
            
            quantile_default = default_values( 1 );
            
            quantile_edit_text_handle = uicontrol();
            quantile_edit_text_handle.Style = 'edit';
            quantile_edit_text_handle.String = quantile_default;
            quantile_edit_text_handle.FontSize = obj.FONT_SIZE;
            quantile_edit_text_handle.Position = [ ...
                RIGHT ...
                obj.VERTICAL_PAD ...
                EDIT_TEXT_WIDTH ...
                obj.HEIGHT ...
                ];
            quantile_edit_text_handle.Callback = edit_text_callbacks{ 1 };
            quantile_edit_text_handle.Parent = button_group_handle;
            
            quantile_slider_handle = uicontrol();
            quantile_slider_handle.Style = 'slider';
            quantile_slider_handle.Position = [ ...
                SLIDER ...
                obj.VERTICAL_PAD ...
                SLIDER_WIDTH ...
                obj.HEIGHT ...
                ];
            quantile_slider_handle.Min = quantile_default - 1;
            quantile_slider_handle.Max = quantile_default + 1;
            quantile_slider_handle.Value = quantile_default;
            quantile_slider_handle.Callback = slider_callbacks{ 1 };
            quantile_slider_handle.Parent = button_group_handle;
            
        end
        
        
        function [ left_handle, right_handle ] = add_point_plot_widgets( ...
                obj, ...
                figure_handle, ...
                left_callback, ...
                right_callback ...
                )
            
            LEFT_WIDTH = 120;
            x_pos = obj.split_across_center( LEFT_WIDTH );
            
            left_handle = uicontrol();
            left_handle.Style = 'checkbox';
            left_handle.String = 'Show Minimum';
            left_handle.FontSize = obj.FONT_SIZE;
            left_handle.Position = [ ...
                x_pos( 1 ) ...
                obj.above_previous() ...
                LEFT_WIDTH ...
                obj.HEIGHT ...
                ];
            left_handle.Callback = left_callback;
            left_handle.Parent = figure_handle;
            
            RIGHT_WIDTH = 140;
            right_handle = uicontrol();
            right_handle.Style = 'checkbox';
            right_handle.String = 'Show Pareto Front';
            right_handle.FontSize = obj.FONT_SIZE;
            right_handle.Position = [ ...
                x_pos( 2 ) ...
                obj.above_previous() ...
                RIGHT_WIDTH ...
                obj.HEIGHT ...
                ];
            right_handle.Callback = right_callback;
            right_handle.Parent = figure_handle;
            
            obj.previous_position = right_handle.Position;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        figure_position
        previous_position
        
    end
    
    
    properties ( Access = private, Constant )
        
        MIN_RESOLUTION = 300;
        VERTICAL_PAD = 6;
        HORIZONTAL_PAD = 6;
        HEIGHT = 23;
        
        FONT_SIZE = 10;
        
        INITIAL_LISTBOX_VALUE = 1;
        
    end
    
    
    methods ( Access = private )
        
        function y_pos = at_top_edge( obj, height )
            
            y_pos = obj.figure_position( 4 ) ...
                - obj.VERTICAL_PAD ...
                - height ...
                - 1;
            
        end
        
        
        function y_pos = at_bottom_edge( obj )
            
            y_pos = obj.VERTICAL_PAD ...
                + 1;
            
        end
        
        
        function y_pos = below_previous( obj, height )
            
            y_pos = obj.previous_position( 2 ) ...
                - obj.VERTICAL_PAD ...
                - height;
            
        end
        
        
        function y_pos = above_previous( obj )
            
            y_pos = obj.previous_position( 2 ) ...
                + obj.previous_position( 4 ) ...
                + obj.VERTICAL_PAD;
            
        end
        
        
        function x_pos = center( obj, widget_width )
            
            x_pos = round( obj.figure_position( 3 ) / 2 ) ...
                - round( widget_width / 2 ) ...
                + 1;
            
        end
        
        
        function x_pos = split_across_center( obj, left_widget_width )
            
            x_pos = [ ...
                obj.center( obj.HORIZONTAL_PAD ) - left_widget_width ...
                obj.center( -obj.HORIZONTAL_PAD ) ...
                ];
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function pos = compute_figure_position( resolution_px )
            
            assert( resolution_px >= UnitSphereResponsePlotWidgets.MIN_RESOLUTION );
            pos = [ ...
                0, ...
                0, ...
                1.8 * resolution_px + 1, ...
                1.1 * make_odd( resolution_px ) ...
                ];
            
        end
        
    end
    
end

