classdef (Sealed) AxesPlotHandle < handle
    
    methods ( Access = public )
        
        % plot_function takes one argument
        function obj = AxesPlotHandle( ...
                axes_handle, ...
                plot_function ...
                )
            
            obj.axes_handle = axes_handle;
            obj.plot_function = plot_function;
            obj.plot_handle = [];
            
        end
        
        
        function update( obj, values, do_update_color_bar, color_bar_range )
            
            obj.remove();
            if nargin < 3
                obj.plot_handle = obj.plot_function( values );
            else
                obj.plot_handle = obj.plot_function( values, do_update_color_bar, color_bar_range );
            end
            
        end
        
        
        function remove( obj )
            
            if ~isempty( obj.plot_handle )
                delete( obj.plot_handle );
                obj.plot_handle = [];
            end
            
        end
        
    end
    
    
    properties ( Access = private )
        
        axes_handle
        plot_function
        plot_handle
        
    end
    
end

