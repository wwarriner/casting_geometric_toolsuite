classdef Cancelable < handle
    %CANCELABLE Summary of this class goes here
    %   Detailed explanation goes here
    
    methods ( Access = public )
        
        function cancel( obj )
            
            obj.do_cancel = true;
            
        end
        
        
        function cancel_requested = was_cancel_requested( obj )
            
            cancel_requested = obj.do_cancel;
            
        end
        
        
        function attach_iteration_complete_callback( obj, callback )
            
            obj.iteration_complete_callback = callback;
            
        end
        
        
        function attach_cancel_callback( obj, callback )
            
            obj.cancel_callback = callback;
            
        end
        
        
        function attach_completion_callback( obj, callback )
            
            obj.completion_callback = callback;
            
        end
        
    
    end
    
    
    methods ( Access = protected )
        
        function keep = keep_iterating( ~ ) 
            
            keep = false;
            
        end
        
        
        function do_next_iteration( ~ )
            
            % do nothing
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function run_cancelable_loop( obj )
            
            obj.reset_do_cancel();
            while obj.keep_iterating()
                if obj.was_cancel_requested()
                    obj.handle_cancel_request();
                    break;
                end
                obj.do_next_iteration();
                obj.iteration_complete_callback();
            end
            obj.handle_completion();
            
        end
        
    end
    
    
    properties ( Access = private )
        
        do_cancel = false;
        iteration_complete_callback;
        cancel_callback;
        completion_callback;
        
    end
    
    
    methods ( Access = private )
        
        function handle_cancel_request( obj )
            
            obj.cancel_callback();
            
        end
        
        
        function handle_completion( obj )
            
            if ~obj.was_cancel_requested()
                obj.completion_callback();
            end
            
        end
        
        function reset_do_cancel( obj )
            
            obj.do_cancel = false;
            
        end
        
    end
    
    
end

