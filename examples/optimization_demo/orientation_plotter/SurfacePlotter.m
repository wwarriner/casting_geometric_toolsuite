classdef (Sealed) SurfacePlotter < handle
    
    methods ( Access = public )
        
        
        function obj = SurfacePlotter( ...
                phi_grid, ...
                theta_grid ...
                )
            
            
            obj.phi_grid = phi_grid;
            obj.theta_grid = theta_grid;
            obj.surface_plot_handle = AxesPlotHandle( @obj.create_plot );
            
        end
        
        
        function update_surface_plot( obj, scaled_values )
            
            obj.surface_plot_handle.update( scaled_values );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        phi_grid
        theta_grid
        
        surface_plot_handle
        
    end
    
    
    methods ( Access = private )
        
        
        function h = create_plot( obj, values )
            
            h = surfacem( ...
                obj.theta_grid, ...
                obj.phi_grid, ...
                values ...
                );
            h.HitTest = 'off';
            %uistack( h, 'bottom' );
            
        end
        
    end
    
end

