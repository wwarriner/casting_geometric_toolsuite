classdef Looper < handle
    % @Looper facilitates iteration of the pde problem by repeatedly
    % iterating until a finish checking function returns true.
    % 
    % TODO: Add callback functionality for per-iteration updates for, say,
    % a dashboard, visualizations, etc.
    
    properties ( SetAccess = private )
        results(:,1)
    end
    
    methods
        % Inputs:
        % - iterator is derived from @IteratorBase
        % - finish_check_fn is a @function_handle taking zero arguments and
        % returning a logical value indicating looping should stop when
        % true and should continue when false.
        function obj = Looper( iterator, finish_check_fn )
            assert( isa( iterator, 'IteratorBase' ) );
            
            obj.iterator = iterator;
            obj.finish_check_fn = finish_check_fn;
        end
        
        % @run loops on the @iterator until @finish_check_fn indicates
        % looping should stop.
        function run( obj )
            while ~obj.is_finished()
                obj.iterator.iterate();
                obj.update_results();
            end
        end
        
        function add_result( obj, result )
            obj.results{ end + 1 } = result;
        end
    end
    
    properties ( Access = private )
        iterator(:,1) cell
        finish_check_fn function_handle
    end
    
    methods ( Access = private )
        function finished = is_finished( obj )
            finished = obj.finish_check_fn();
        end
        
        function update_results( obj )
            for i = 1 : numel( obj.results )
                obj.results{ i }.update();
            end
        end
    end
    
end

