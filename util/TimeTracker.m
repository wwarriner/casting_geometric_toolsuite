classdef (Sealed) TimeTracker < handle
    
    methods ( Access = public )
        
        function obj = TimeTracker()
            
            obj.times = [];
            obj.time_steps = [];
            
        end
        
        
        function count = get_count( obj )
            
            assert( numel( obj.times ) == numel( obj.time_steps ) );
            
            count = numel( obj.times );
            
        end
        
        
        % i counts backward, i = 1 is most recent
        function time = get_time( obj, i )
            
            if nargin < 2
                i = 1;
            end
            
            if obj.get_count() < i
                time = 0;
            else
                time = obj.times( end - i + 1 );
            end
            
        end
        
        
        function times = get_times( obj )
            
            times = obj.times;
            
        end
        
        
        function total = get_total_time( obj )
            
            total = obj.get_time();
            
        end
        
        
        % i counts backward, i = 1 is most recent
        function step = get_time_step( obj, i )
            
            if nargin < 2
                i = 1;
            end
            
            step = obj.time_steps( end - i + 1 );
            
        end
        
        
        function time_steps = get_time_steps( obj )
            
            time_steps = obj.time_steps;
            
        end
        
        
        function append_time_step( obj, step )
            
            obj.time_steps( end + 1 ) = step;
            if isempty( obj.times )
                obj.times( end + 1 ) = step;
            else
                obj.times( end + 1 ) = obj.times( end ) + step;
            end
            
        end
        
    end
    
    
    properties ( Access = private )
        
        times
        time_steps
        
    end
    
end

