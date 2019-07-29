classdef Scaling < handle
    
    properties
        factor(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1.0
        origin(1,3) double {mustBeReal,mustBeFinite} = [ 0 0 0 ]
    end
    
    methods
        function v = apply( obj, v )
            assert( isvector( v ) || ismatrix( v ) );
            assert( size( v, 2 ) == 3 );
            
            v = v - obj.origin;
            v = v .* obj.factor;
            v = v + obj.origin;
        end
    end
    
end

