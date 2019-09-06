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
            ldy = obj.y( 2 ) - obj.y( 1 );
            ldx = obj.x( 2 ) - obj.x( 1 );
            rdy = obj.y( end - 1 ) - obj.y( end );
            rdx = obj.x( end - 1 ) - obj.x( end );
            obj.sp = slmengine( ...
                obj.x, obj.y, ...
                'knots', kk, ...
                'decreasing', 'on', ...
                'leftvalue', obj.y( 1 ), ...
                'leftslope', ldy / ldx, ...
                'rightvalue', obj.y( end ), ...
                'rightslope', rdy / rdx ...
                );
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

