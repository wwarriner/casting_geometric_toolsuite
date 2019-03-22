classdef (Sealed) AxesPlotHandle < handle
    
    methods ( Access = public )
        
        % plot_function takes one argument
        function obj = AxesPlotHandle( plot_function )
            
            obj.plot_function = plot_function;
            obj.plot_handle = [];
            
        end
        
        
        function update( obj, values )
            
            obj.remove();
            obj.plot_handle = obj.plot_function( values );
            
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

