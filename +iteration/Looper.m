classdef Looper < handle
    
    methods ( Access = public )
        
        function obj = Looper( iterator, finish_check_fn )
            obj.iterator = iterator;
            obj.finish_check_fn = finish_check_fn;
        end
        
        function run( obj )
            while ~obj.is_finished()
                obj.iterator.iterate();
                obj.update_results();
            end
        end
        
    end
    
    
    properties ( Access = private )
        iterator(1,1)
        finish_check_fn(1,1) function_handle = @()[]
        results(:,1)
    end
    
    
    methods ( Access = private )
        
        function finished = is_finished( obj )
            finished = obj.finish_check_fn();
        end
        
        function update_results( obj )
            for i = 1 : numel( obj.results )
                obj.results( i ).update();
            end
        end
        
    end
    
end

