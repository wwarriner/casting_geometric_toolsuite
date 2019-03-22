classdef PointReporterWidget < handle
    
    methods ( Access = public )
        
        function obj = PointReporterWidget( ...
                figure_handle, ...
                corner_pos, ...
                font_size ...
                )
            
            h = uicontrol();
            h.Style = 'text';
            h.String = 'Click on the axes to get point data!';
            h.FontSize = font_size;
            h.Position = [ ...
                corner_pos ...
                obj.get_width() ...
                obj.get_height( font_size ) ...
                ];
            h.Parent = figure_handle;
            
            obj.static_text_handle = h;
            
            obj.plot_handle = ...
                AxesPlotHandle( @obj.create_plot );
            
        end
        
        
        function update_picked_point( obj, point, value )
            
            pattern = [ ...
                'Selected Point is @X: %.2f' degree_symbol() ...
                ', @Y: %.2f' degree_symbol() ...
                ', Value: %s' ...
                ];
            [ PHI_INDEX, THETA_INDEX ] = unit_sphere_plot_indices();
            obj.static_text_handle.String = sprintf( ...
                pattern, ...
                point( PHI_INDEX ), ...
                point( THETA_INDEX ), ...
                num2str( value ) ...
                );
            
            obj.plot_handle.remove();
            obj.plot_handle.update( point );
            
        end
        
        
        function set_background_color( obj, color )
            
            obj.static_text_handle.BackgroundColor = color;
            
        end
        
        
        function pos = get_position( obj )
            
            pos = obj.static_text_handle.Position;
            
        end
        
        
    end
    
    
    methods ( Access = public, Static )
        
        function height = get_height( font_size )
            
            height = get_height( font_size );
            
        end
        
        
        function width = get_width()
            
            width = PointReporterWidget.WIDTH;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        static_text_handle
        plot_handle
        
    end
    
    
    properties ( Access = private, Constant )
        
        WIDTH = 600;
        
    end
    
    
    methods ( Access = private, Static )
        
        % color from http://jfly.iam.u-tokyo.ac.jp/color/#redundant2
        function h = create_plot( point )
            
            h = add_point_plot( point );
            h.LineStyle = 'none';
            h.Marker = 'd';
            h.MarkerSize = 8;
            h.MarkerEdgeColor = 'k';
            h.MarkerFaceColor = [ 0.35 0.7 0.9 ];
            h.HitTest = 'off';
            
        end
        
    end
    
    
end

