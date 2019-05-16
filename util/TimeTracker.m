classdef (Sealed) TimeTracker < handle
    
    methods ( Access = public )
        
        function obj = TimeTracker( initial_time_step )
            
            obj.times = 0;
            obj.time_steps = initial_time_step;
            
        end
        
        
        function count = get_count( obj )
            
            assert( numel( obj.times ) == numel( obj.time_steps ) );
            
            count = numel( obj.times );
            
        end
        
        
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
        
        
        function step = get_time_step( obj, i )
            
            if nargin < 2
                i = 1;
            end
            
            step = obj.time_steps( end - i + 1 );
            
        end
        
        
        function append_time_step( obj, step )
            
            obj.time_steps( end + 1 ) = step;
            obj.times( end + 1 ) = obj.times( end ) + step;
            
        end
        
    end
    
    
    properties ( Access = private )
        
        times
        time_steps
        
    end
    
end

