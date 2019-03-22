classdef ObjectivePickerWidget < handle
    
    methods ( Access = public )
        
        function obj = ObjectivePickerWidget( ...
                figure_handle, ...
                corner_pos, ...
                font_size, ...
                titles, ...
                initial_index, ...
                list_box_callback ...
                )
            
            h = uicontrol();
            h.Style = 'popupmenu';
            h.String = titles;
            h.Value = initial_index;
            h.FontSize = font_size;
            h.Position = [ ...
                corner_pos, ...
                obj.get_width() ...
                obj.get_height( font_size ) ...
                ];
            h.Callback = @(h,e)list_box_callback(h,e,obj);
            h.Parent = figure_handle;
            
            obj.list_box_handle = h;
            obj.selection_value = initial_index;
            
        end
        
        
        function changed = update_selection( obj )
            
            new_value = obj.get_selection_index();
            changed = obj.update_selection_value( new_value );
            
        end
        
        
        function index = get_selection_index( obj )
            
            index = obj.list_box_handle.Value;
            
        end
        
        
        function pos = get_position( obj )
            
            pos = obj.list_box_handle.Position;
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function height = get_height( font_size )
            
            height = get_height( font_size );
            
        end
        
        
        function width = get_width()
            
            width = ObjectivePickerWidget.WIDTH;
            
        end
        
    end
    
    
    properties ( Access = public )
        
        list_box_handle
        
        selection_value
        
    end
    
    
    properties ( Access = private, Constant )
        
        WIDTH = 300;
        
    end
    
    
    methods ( Access = private )
        
        function changed = update_selection_value( obj, new_value )
            
            changed = obj.has_selection_value_changed( new_value );
            obj.update_handle_selection_value( new_value );
            
        end
        
        
        function changed = has_selection_value_changed( obj, new_value )
            
            changed = obj.selection_value ~= new_value;
            
        end
        
        
        function update_handle_selection_value( obj, new_value )
            
            obj.list_box_handle.Value = new_value;
            obj.selection_value = new_value;
            
        end
        
    end
    
end

