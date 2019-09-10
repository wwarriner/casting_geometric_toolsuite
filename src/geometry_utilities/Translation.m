classdef Translation < handle & matlab.mixin.Copyable
    
    properties
        shift(1,3) double {mustBeReal,mustBeFinite} = [ 0 0 0 ]
    end
    
    methods
        function v = apply( obj, v )
            assert( isvector( v ) || ismatrix( v ) );
            assert( size( v, 2 ) == 3 );
            
            v = v + obj.shift;
        end
    end
    
end

