classdef ThresholdingWidgets < handle
    
    properties ( Access = public, Constant )
        
        NO_THRESHOLD = 1;
        VALUE_THRESHOLD = 2;
        QUANTILE_THRESHOLD = 3;
        COUNT = 3;
        
    end
    
    
    methods

        function obj = ThresholdingWidgets( ...
                figure_handle, ...
                corner_pos, ...
                padding, ...
                font_size, ...
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
            
            obj.selected_id = default_id;
            
            height_each = get_height( font_size );
            height = obj.get_height_internal( ...
                obj.COUNT, ...
                padding, ...
                height_each ...
                );
            
            h = uibuttongroup();
            h.Units = 'pixels';
            h.Position = [ ...
                corner_pos ...
                obj.get_width() ...
                height ...
                ];
            h.BorderType = 'none';
            h.SelectionChangedFcn = selection_changed_function;
            h.Parent = figure_handle;
            
            obj.widget_handles = containers.Map( ...
                'keytype', 'double', ...
                'valuetype', 'any' ...
                );
            ids = obj.get_ids();
            for i = 1 : obj.COUNT
            
                id = ids{ i };
                y_pos = obj.get_y_pos( ...
                    id, ...
                    padding, ...
                    height_each ...
                    );
                value_picker_fn = value_picker_fns( id );
                if id == obj.NO_THRESHOLD
                    obj.widget_handles( id ) = ThresholdingOption( ...
                        h, ...
                        id, ...
                        value_picker_fn, ...
                        y_pos, ...
                        font_size, ...
                        labels( id ) ...
                        );
                else
                    obj.widget_handles( id ) = ThresholdingOption( ...
                        h, ...
                        id, ...
                        value_picker_fn, ...
                        y_pos, ...
                        font_size, ...
                        labels( id ), ...
                        default_mins( id ), ...
                        default_maxs( id ), ...
                        default_values( id ), ...
                        edit_text_callback, ...
                        slider_callback ...
                        );
                end
                
            end
            obj.button_group_handle = h;
            
        end
        
        
        function set_background_color( obj, color )
            
            obj.button_group_handle.BackgroundColor = color;
            ids = obj.widget_handles.keys();
            for i = 1 : obj.widget_handles.Count()
                
                id = ids{ i };
                h = obj.widget_handles( id );
                h.set_background_color( color );
                
            end
            
        end
        
        
        function select( obj, id )
            
            h = obj.widget_handles( obj.selected_id );
            h.select();
            obj.selected_id = id;
            
        end
        
        
        function values = pick_selected_values( obj )
            
            ids = obj.widget_handles.keys();
            for i = 1 : obj.widget_handles.Count()
                
                id = ids{ i };
                h = obj.widget_handles( id );
                if h.is_selected()
                    values = h.pick_values();
                end
                
            end
            
        end
        
        
        function update_value_range( obj, range )
            
            h = obj.widget_handles( obj.VALUE_THRESHOLD );
            h.set_range( range );
            
        end
        
        
        function set_position( obj, pos )
            
            obj.button_group_handle.Position = pos;
            
        end
        
        
        function pos = get_position( obj )
            
            pos = obj.button_group_handle.Position;
            
        end
        
        
        function height = get_height( obj )
            
            pos = obj.get_position();
            height = pos( 4 );
            
        end

    end
    
    
    methods ( Access = public, Static )
        
        function ids = get_ids()
            
            ids = { ...
                ThresholdingWidgets.NO_THRESHOLD, ...
                ThresholdingWidgets.VALUE_THRESHOLD, ...
                ThresholdingWidgets.QUANTILE_THRESHOLD ...
                };
            assert( numel( ids ) == ThresholdingWidgets.COUNT );
            
        end
        
        
        function height = get_height_internal( count, padding, height_each )
            
            height = ( padding + height_each ) * count + padding;
            
        end
        
        
        function width = get_width()
            
            width = ThresholdingOption.get_width();
            
        end
        
    end


    properties ( Access = private )

        button_group_handle
        widget_handles
        
        selected_id

    end
    
    
    methods ( Access = private, Static )
        
        function y = get_y_pos( id, padding, height_each )
            
            y = ThresholdingWidgets.get_height_internal( id - 1, padding, height_each );
            
        end
        
    end

end

