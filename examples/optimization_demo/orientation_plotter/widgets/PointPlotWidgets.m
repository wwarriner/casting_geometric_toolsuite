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
            obj.pareto_front_check_box_handle = par_h;
            
            obj.minimum_plot_handle = ...
                AxesPlotHandle( @obj.create_minimum_plot );
            obj.pareto_front_plot_handle = ...
                AxesPlotHandle( @obj.create_pareto_front_plot );
            
        end
        
        
        function set_background_color( obj, color )
            
            obj.minimum_check_box_handle.BackgroundColor = color;
            obj.pareto_front_check_box_handle.BackgroundColor = color;
            
        end
        
        
        function update_minimum( obj, point )
            
            switch obj.minimum_check_box_handle.Value
                case false
                    obj.minimum_plot_handle.remove();
                case true
                    obj.minimum_plot_handle.remove();
                    obj.minimum_plot_handle.update( point );
                otherwise
                    assert( false );
            end
            
        end
        
        
        function update_pareto_front( obj, points )
            
            switch obj.pareto_front_check_box_handle.Value
                case false
                    obj.pareto_front_plot_handle.remove();
                case true
                    obj.pareto_front_plot_handle.remove();
                    obj.pareto_front_plot_handle.update( points );
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
        pareto_front_check_box_handle
        
        minimum_plot_handle
        pareto_front_plot_handle
        
    end
    
    
    properties ( Access = private, Constant )
        
        MIN_WIDTH = 140;
        PAR_WIDTH = 140;
        
    end
    
    
    methods ( Access = private, Static )
        
        % color from http://jfly.iam.u-tokyo.ac.jp/color/#redundant2
        function plot_handle = create_minimum_plot( points )
            
            plot_handle = add_point_plot( points );
            plot_handle.LineStyle = 'none';
            plot_handle.Marker = 's';
            plot_handle.MarkerSize = 8;
            plot_handle.MarkerEdgeColor = 'k';
            plot_handle.MarkerFaceColor = [ 0.9 0.6 0 ];
            plot_handle.HitTest = 'off';
            
        end
        
        
        % color from http://jfly.iam.u-tokyo.ac.jp/color/#redundant2
        function plot_handle = create_pareto_front_plot( points )
            
            plot_handle = add_point_plot( points );
            plot_handle.LineStyle = 'none';
            plot_handle.Marker = 'o';
            plot_handle.MarkerSize = 4;
            plot_handle.MarkerEdgeColor = 'k';
            plot_handle.MarkerFaceColor = [ 0 0.6 0.5 ];
            plot_handle.HitTest = 'off';
            
        end
        
    end
    
end

