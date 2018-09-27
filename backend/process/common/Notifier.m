classdef Notifier < handle
    %OBSERVED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties ( Access = private )
        
        observer
        
    end
    
    
    methods ( Access = public )
        
        function observer = get_observer( obj )
            
            observer = obj.observer();
            
        end
        
        
        function attach_observer( obj, observer )
            
            obj.observer = observer;
            
        end
        
        
        function has = has_observer( obj )
            
            has = ~isempty( obj.observer );
            
        end
        
        
        function notify_observer( obj, varargin )
            
            obj.observer.printf( varargin{ : } );
            
        end
        
    end
    
end

