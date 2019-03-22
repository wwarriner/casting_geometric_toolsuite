classdef PointPlotWidgets < handle
    
    methods ( Access = public )
        
        function obj = PointPlotWidgets( ...
                figure_handle, ...
                corner_pos, ...
                font_size, ...
                check_box_callback ...
                )
            
            min_h = uicontrol();
            min_h.Style = 'checkbox';
            min_h.String = 'Show Minimum';
            min_h.FontSize = font_size;
            min_h.Position = [ ...
                corner_pos ...
                obj.MIN_WIDTH ...
                obj.get_height( font_size ) ...
                ];
            min_h.Callback = check_box_callback;
            min_h.Parent = figure_handle;
            
            par_h = uicontrol();
            par_h.Style = 'checkbox';
            par_h.String = 'Show Pareto Front';
            par_h.FontSize = font_size;
            par_h.Position = [ ...
                corner_pos( 1 ) + obj.MIN_WIDTH ...
                corner_pos( 2 ) ...
                obj.PAR_WIDTH ...
                obj.get_height( font_size ) ...
                ];
            par_h.Callback = check_box_callback;
            par_h.Parent = figure_handle;
            
            obj.minimum_check_box_handle = min_h;
            obj.pareto_check_box_handle = par_h;
            
        end
        
        
        function set_background_color( obj, color )
            
            obj.minimum_check_box_handle.BackgroundColor = color;
            obj.pareto_check_box_handle.BackgroundColor = color;
            
        end
        
        
        function update_minimum( obj, response_axes, minimum_point )
            
            switch obj.minimum_check_box_handle.Value
                case false
                    response_axes.remove_minimum();
                case true
                    response_axes.update_minimum( minimum_point );
                otherwise
                    assert( false );
            end
            
        end
        
        
        function update_pareto_front( obj, response_axes, pareto_front_points )
            
            switch obj.pareto_check_box_handle.Value
                case false
                    response_axes.remove_pareto_fronts();
                case true
                    response_axes.update_pareto_fronts( pareto_front_points );
                otherwise
                    assert( false );
            end
            
        end
        
        
        function pos = get_position( obj )
            
            pos = [ ...
                obj.minimum_check_box_handle.Position( 1 : 3 ) ...
                obj.get_width() ...
                ];
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function height = get_height( font_size )
            
            height = get_height( font_size );
            
        end
        
        
        function width = get_width()
            
            width = PointPlotWidgets.MIN_WIDTH + ...
                PointPlotWidgets.PAR_WIDTH;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        minimum_check_box_handle
        pareto_check_box_handle
        
    end
    
    
    properties ( Access = private, Constant )
        
        MIN_WIDTH = 140;
        PAR_WIDTH = 140;
        
    end
    
end

