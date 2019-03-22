classdef (Sealed) AxesPlotHandle < handle
    
    methods ( Access = public )
        
        % plot_function takes one argument
        function obj = AxesPlotHandle( plot_function )
            
            obj.plot_function = plot_function;
            obj.plot_handle = [];
            
        end
        
        
        function update( obj, axh, values, do_update_color_bar, color_bar_range )
            
            obj.remove();
            if nargin < 4
                obj.plot_handle = obj.plot_function( axh, values );
            else
                obj.plot_handle = obj.plot_function( axh, values, do_update_color_bar, color_bar_range );
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
        
        plot_function
        plot_handle
        
    end
    
end

