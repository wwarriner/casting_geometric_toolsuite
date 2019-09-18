classdef Sequence < handle
    
    methods
        function obj = Sequence( fn )
            obj.iteration = 1;
            obj.fn = fn;
        end
        
        function dt = next( obj )
            dt = obj.fn( obj.iteration );
            
            assert( isscalar( dt ) );
            assert( isa( dt, "double" ) );
            assert( isreal( dt ) );
            assert( isfinite( dt ) );
            
            obj.iteration = obj.iteration + 1;
        end
    end
    
    properties
        iteration(1,1) double = 1
        fn function_handle
    end
    
end

