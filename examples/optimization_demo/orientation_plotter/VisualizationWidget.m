classdef VisualizationWidget < handle
    
    methods ( Access = public )
        
        function obj = VisualizationWidget( ...
                figure_handle, ...
                corner_pos, ...
                font_size, ...
                button_callback ...
                )
            
            h = uicontrol();
            h.Style = 'pushbutton';
            h.String = 'Visualize Picked Point...';
            h.FontSize = font_size;
            h.Position = [ ...
                corner_pos ...
                obj.get_width() ...
                obj.get_height( font_size ) ...
                ];
            h.Callback = button_callback;
            h.Parent = figure_handle;
            
            obj.button_handle = h;
            
        end
        
        
        function figure_handle = generate_visualization( ...
                obj, ...
                point, ...
                response_data ...
                )
            
            figure_handle = figure();
            figure_handle.Name = sprintf( ...
                'Visualization with @X: %.2f and @Y: %.2f', ...
                rad2deg( point( 1 ) ), ...
                rad2deg( point( 2 ) ) ...
                );
            figure_handle.NumberTitle = 'off';
            figure_handle.MenuBar = 'none';
            figure_handle.ToolBar = 'none';
            figure_handle.DockControls = 'off';
            figure_handle.Resize = 'off';
            cameratoolbar( figure_handle, 'show' );
            
            axh = axes( figure_handle );
            axh.Color = 'none';
            hold( axh, 'on' );
            rotated_component_fv = response_data.get_rotated_component_fv( point );
            rch = patch( axh, rotated_component_fv, 'SpecularStrength', 0.0 );
            rch.FaceColor = [ 0.9 0.9 0.9 ];
            rch.EdgeColor = 'none';
            
            rotated_feeder_fvs = response_data.get_rotated_feeder_fvs( point );
            for i = 1 : numel( rotated_feeder_fvs )
                
                rfh = patch( ...
                    axh, ...
                    rotated_feeder_fvs{ i }, ...
                    'SpecularStrength', ...
                    0.0 ...
                    );
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
            cor_point = response_data.get_center_of_rotation();
            
            pa = PrettyAxes3D( min_point, max_point, cor_point );
            pa.draw( axh );
            
            bm = BasicMold( min_point, max_point, cor_point );
            bm.draw( axh );
            
            view( 3 );
            light( axh, 'Position', [ 0 0 -1 ] );
            light( axh, 'Position', [ 0 0 1 ] );
            
            axis( axh, 'equal', 'vis3d', 'off' );
            
        end
        
        
        function pos = get_position( obj )
            
            pos = obj.button_handle.Position;
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function height = get_height( font_size )
            
            height = get_height( font_size );
            
        end
        
        
        function width = get_width()
            
            width = VisualizationWidget.WIDTH;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        button_handle
        
    end
    
    
    properties ( Access = private, Constant )
        
        WIDTH = 200;
        
    end
    
end

