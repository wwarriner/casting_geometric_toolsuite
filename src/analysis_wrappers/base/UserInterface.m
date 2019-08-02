classdef UserInterface < Cancelable & Notifier & Printer & Saveable & handle
    
    % Common mixin collector
    methods ( Access = protected )
        function printf( obj, varargin )
            obj.printf@Print( varargin{ : } );
            if obj.has_observer()
                obj.notify_observer( varargin{ : } );
            end
        end
    end
    
end

