classdef SplineGenerator < handle
    
    methods ( Access = public )
        
        function obj = SplineGenerator( degree, x, y )
            
            obj.degree = degree;
            obj.x = x;
            obj.y = y;
            
        end
        
        
        function error = generate( obj, piece_count )
            
            % spap2 built-in method
%             obj.sp = spap2( piece_count, obj.degree + 1, obj.x, obj.y );
%             obj.yy = fnval( obj.sp, obj.x );
            
            % shape language modeling engine method
            r = range( obj.x );
            kk = linspace( 0, 1, piece_count + 1 ).^2 * r + min( obj.x, [], 'all' );
            kk = [ kk max( obj.x, [], 'all' ) - r * ( 1 - linspace( 0, 1, piece_count + 1 ) ).^2 ];
            kk = unique( sort( kk ) ).';
            obj.sp = splinefit( obj.x, obj.y, kk, 1e-4, 0 );
            obj.yy = quickeval( obj.x, obj.sp.knots, obj.sp.coef(:,1), obj.sp.coef(:,2) );
            
            % error
            abs_error = max( abs( obj.yy - obj.y ) );
            obj.error = abs_error ./ range( obj.y );
            error = obj.error;
        
        end
        
    end
    
    
    properties ( GetAccess = public, SetAccess = private )
        
        degree
        x
        y
        
        sp
        yy
        error
        
    end
    
end

