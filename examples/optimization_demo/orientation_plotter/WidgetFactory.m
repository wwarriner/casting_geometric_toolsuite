classdef (Sealed) WidgetFactory < handle
    
    methods ( Access = public )
        
        function obj = WidgetFactory( resolution_px )
        
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
        
        
        function h = add_visualization_widget( ....
                obj, ...
                figure_handle, ...
                button_callback ...
                )
            
            x = obj.center( VisualizationWidget.get_width() );
            y = obj.below_previous( VisualizationWidget.get_height( obj.FONT_SIZE ) );
            h = VisualizationWidget( ...
                figure_handle, ...
                [ x y ], ...
                obj.FONT_SIZE, ...
                button_callback ...
                );
            
            obj.previous_position = h.get_position();
            
        end
        
        
        function h = add_objective_picker_widget( ...
                obj, ...
                figure_handle, ...
                titles, ...
                initial_index, ...
                list_box_callback ...
                )
            
            x = obj.center( ObjectivePickerWidget.get_width() );
            y = obj.below_previous( ObjectivePickerWidget.get_height( obj.FONT_SIZE ) );
            h = ObjectivePickerWidget( ...
                figure_handle, ...
                [ x y ], ...
                obj.FONT_SIZE, ...
                titles, ...
                initial_index, ...
                list_box_callback ...
                );
            
            obj.previous_position = h.get_position();
            
        end
        
        
        function add_response_axes( ...
                obj, ...
                figure_handle, ...
                axes_generator, ...
                phi_grid, ...
                theta_grid, ...
                button_down_callback ...
                )
            
            axes_generator.create_axes( ...
                figure_handle, ...
                button_down_callback, ...
                phi_grid, ...
                theta_grid ...
                );
            pos = axes_generator.get_axes_position();
            
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
                obj.center( pos( 3 ) ), ...
                obj.below_previous( pos( 4 ) ), ...
                pos( 3 ), ...
                pos( 4 ) ...
                ];
            axes_generator.set_axes_position( pos );
            
            obj.previous_position = pos;
            
        end
        
        
        function h = add_point_plot_widgets( ...
                obj, ...
                figure_handle, ...
                check_box_callback ...
                )
            
            x = obj.center( PointPlotWidgets.get_width() );
            y = obj.below_previous( PointPlotWidgets.get_height( obj.FONT_SIZE ) );
            h = PointPlotWidgets( ...
                figure_handle, ...
                [ x y ], ...
                obj.FONT_SIZE, ...
                check_box_callback ...
                );
            
            obj.previous_position = h.get_position();
            
        end
        
        
        function h = add_thresholding_widget( ...
                obj, ...
                figure_handle, ...
                default_id, ...
                value_picker_fns, ...
                labels, ...
                default_mins, ...
                default_maxs, ...
                default_values, ...
                selection_changed_function, ...
                edit_text_callback, ...
                slider_callback ...
                )
            
            x = obj.center( ThresholdingWidgets.get_width() );
            h = ThresholdingWidgets( ...
                figure_handle, ...
                [ x, 0 ], ...
                obj.VERTICAL_PAD, ...
                obj.FONT_SIZE, ...
                default_id, ...
                value_picker_fns, ...
                labels, ...
                default_mins, ...
                default_maxs, ...
                default_values, ...
                selection_changed_function, ...
                edit_text_callback, ...
                slider_callback ...
                );
            pos = h.get_position();
            pos( 2 ) = obj.below_previous( h.get_height() );
            h.set_position( pos );
            
            obj.previous_position = h.get_position();
            
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
        
    end
    
    
    methods ( Access = private )
        
        function y_pos = at_top_edge( obj, height )
            
            y_pos = obj.figure_position( 4 ) ...
                - obj.VERTICAL_PAD ...
                - height ...
                - 1;
            
        end
        
        
        function y_pos = below_previous( obj, height )
            
            y_pos = obj.previous_position( 2 ) ...
                - obj.VERTICAL_PAD ...
                - height;
            
        end
        
        
        function x_pos = center( obj, widget_width )
            
            x_pos = round( obj.figure_position( 3 ) / 2 ) ...
                - round( widget_width / 2 ) ...
                + 1;
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function pos = compute_figure_position( resolution_px )
            
            assert( resolution_px >= WidgetFactory.MIN_RESOLUTION );
            pos = [ ...
                0, ...
                0, ...
                1.8 * resolution_px + 1, ...
                1.1 * make_odd( resolution_px ) ...
                ];
            
        end
        
    end
    
end

