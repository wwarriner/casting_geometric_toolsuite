classdef ThresholdingOption < handle
    
    properties ( GetAccess = public, SetAccess = private )
        
        id
        
    end
    
    
    methods ( Access = public )
        
        function obj = ThresholdingOption( ...
                button_group_handle, ...
                id, ...
                value_picker_fn, ...
                y_pos, ...
                font_size, ...
                label, ...
                default_min, ...
                default_max, ...
                default_threshold_value, ...
                edit_text_callback, ...
                slider_callback ...
                )
            
            obj.button_group_handle = button_group_handle;
            obj.id = id;
            obj.value_picker_fn = value_picker_fn;
            obj.radio_button_handle = obj.prepare_radio_button( ...
                button_group_handle, ...
                y_pos, ...
                font_size, ...
                label ...
                );
            if nargin > 6
                obj.edit_text_handle = obj.prepare_edit_text( ...
                    button_group_handle, ...
                    y_pos, ...
                    font_size, ...
                    default_threshold_value, ...
                    @(h,e)edit_text_callback(h,e,obj) ...
                    );
                obj.slider_handle = obj.prepare_slider( ...
                    button_group_handle, ...
                    y_pos, ...
                    font_size, ...
                    default_min, ...
                    default_max, ...
                    default_threshold_value, ...
                    @(h,e)slider_callback(h,e,obj) ...
                    );
                obj.update_threshold_value( default_threshold_value );
            end
            
        end
        
        
        function set_background_color( obj, color )
            
            obj.radio_button_handle.BackgroundColor = color;
            obj.edit_text_handle.BackgroundColor = color;
            %obj.slider_handle.BackgroundColor = color;
            
        end
        
        
        function select( obj )
            
            obj.radio_button_handle.Value = 1;
            
        end
        
        
        function selected = is_selected( obj )
            
            selected = obj.radio_button_handle.Value == 1;
            
        end
        
        
        function set_range( obj, range )
            
            old_value = obj.threshold_value;
            old_min = obj.slider_handle.Min;
            old_max = obj.slider_handle.Max;
            ratio = ( old_value - old_min ) / ( old_max - old_min );
            
            obj.slider_handle.Min = range.min;
            obj.slider_handle.Max = range.max;
            new_value = ratio * ( range.max - range.min ) + range.min;
            obj.update_threshold_value( new_value );
            
        end
        
        
        function values = pick_values( obj )
            
            threshold = obj.get_threshold_value();
            values = obj.value_picker_fn( threshold );
            
        end
        
        
        function value = get_threshold_value( obj )
            
            value = obj.threshold_value;
            
        end
        
        
        function changed = update_threshold_value_from_edit_text( obj )
            
            new_value = obj.get_edit_text_threshold_value();
            changed = obj.update_threshold_value( new_value );
            
        end
        
        
        function changed = update_threshold_value_from_slider( obj )
            
            new_value = obj.get_slider_threshold_value();
            changed = obj.update_threshold_value( new_value );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function width = get_width()
            
            width = ThresholdingOption.RADIO_BUTTON_WIDTH + ...
                ThresholdingOption.EDIT_TEXT_WIDTH + ...
                ThresholdingOption.SLIDER_WIDTH;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        button_group_handle
        value_picker_fn
        
        radio_button_handle
        edit_text_handle
        slider_handle
        
        threshold_value
        
    end
    
    
    properties ( Access = private, Constant )
        
        RADIO_BUTTON_X_POS = 0;
        
        RADIO_BUTTON_WIDTH = 200;
        EDIT_TEXT_WIDTH = 120;
        SLIDER_WIDTH = 300;
        
    end
    
    
    methods ( Access = private )
        
        function value = get_edit_text_threshold_value( obj )
            
            value = str2double( obj.edit_text_handle.String );
            
        end
        
        
        function value = get_slider_threshold_value( obj )
            
            value = obj.slider_handle.Value;
            
        end
        
        
        function changed = update_threshold_value( obj, new_value )
            
            constrained_value = obj.constrain_threshold_value( new_value );
            changed = obj.has_threshold_value_changed( constrained_value );
            obj.update_handle_threshold_values( constrained_value );
            
        end
        
        
        function constrained_value = constrain_threshold_value( obj, new_value )
            
            if isnan( new_value )
                constrained_value = obj.threshold_value;
            elseif new_value < obj.get_min_threshold_value()
                constrained_value = obj.get_min_threshold_value();
            elseif obj.get_max_threshold_value() < new_value
                constrained_value = obj.get_max_threshold_value();
            else
                constrained_value = new_value;
            end
            
        end
        
        
        function value = get_min_threshold_value( obj )
            
            value = obj.slider_handle.Min;
            
        end
        
        
        function value = get_max_threshold_value( obj )
            
            value = obj.slider_handle.Max;
            
        end
        
        
        function changed = has_threshold_value_changed( obj, constrained_value )
            
            changed = obj.threshold_value ~= constrained_value;
            
        end
        
        
        function update_handle_threshold_values( obj, constrained_value )
            
            obj.edit_text_handle.String = num2str( constrained_value );
            obj.slider_handle.Value = constrained_value;
            obj.threshold_value = constrained_value;
            
        end
        
    end
    
    
    % construction
    methods ( Access = private )
        
        function h = prepare_radio_button( ...
                obj, ...
                button_group_handle, ...
                y_pos, ...
                font_size, ...
                label ...
                )
            
            h = uicontrol();
            h.Style = 'radiobutton';
            h.String = label;
            h.FontSize = font_size;
            h.Position = [ ...
                obj.RADIO_BUTTON_X_POS ...
                y_pos ...
                obj.RADIO_BUTTON_WIDTH ...
                get_height( font_size ) ...
                ];
            h.Parent = button_group_handle;
            
        end
        
        
        function h = prepare_edit_text( ...
                obj, ...
                button_group_handle, ...
                y_pos, ...
                font_size, ...
                default_threshold_value, ...
                edit_text_callback ...
                )
            
            h = uicontrol();
            h.Style = 'edit';
            h.String = num2str( default_threshold_value );
            h.FontSize = font_size;
            h.Position = [ ...
                obj.get_edit_text_x_pos() ...
                y_pos ...
                obj.EDIT_TEXT_WIDTH ...
                get_height( font_size ) ...
                ];
            h.Parent = button_group_handle;
            h.Callback = edit_text_callback;
            
        end
        
        
        function h = prepare_slider( ...
                obj, ...
                button_group_handle, ...
                y_pos, ...
                font_size, ...
                default_min, ...
                default_max, ...
                default_threshold_value, ...
                slider_callback ...
                )
            
            h = uicontrol();
            h.Style = 'slider';
            h.Min = default_min;
            h.Max = default_max;
            h.Value = default_threshold_value;
            h.Position = [ ...
                obj.get_slider_x_pos() ...
                y_pos ...
                obj.SLIDER_WIDTH ...
                get_height( font_size ) ...
                ];
            h.Parent = button_group_handle;
            h.Callback = slider_callback;
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function x = get_edit_text_x_pos()
            
            x = ThresholdingOption.RADIO_BUTTON_X_POS + ...
                ThresholdingOption.RADIO_BUTTON_WIDTH;
            
        end
        
        
        function x = get_slider_x_pos()
            
            x = ThresholdingOption.get_edit_text_x_pos() + ...
                ThresholdingOption.EDIT_TEXT_WIDTH;
            
        end
        
    end
    
end

