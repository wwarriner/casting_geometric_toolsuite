classdef FieldInterface < handle
    
    methods ( Access = public )
        
        function obj = FieldInterface( values )
            obj.values = values;
        end
        
    end
    
    methods ( Access = public ) % operators
        
        function value = double(obj)
            value = obj.values;
        end
        
        function varargout = map( obj, fn )
            [varargout{1:nargout}] = fn( double(obj) );
        end
        
        function f = plus( obj1, obj2 )
            f = field.FieldInterface( double(obj1) + double(obj2) );
        end
        
        function f = minus( obj1, obj2 )
            f = field.FieldInterface( double(obj1) - double(obj2) );
        end
        
        function f = uminus( obj )
            f = field.FieldInterface( -double(obj) );
        end
        
        function f = uplus( obj )
            f = field.FieldInterface( +double(obj) );
        end
        
        function f = times( obj1, obj2 )
            f = field.FieldInterface( double(obj1) .* double(obj2) );
        end
        
        function f = rdivide( obj1, obj2 )
            f = field.FieldInterface( double(obj1) ./ double(obj2) );
        end
        
        function f = ldivide( obj1, obj2 )
            f = field.FieldInterface( double(obj1) .\ double(obj2) );
        end
        
        function f = power( obj1, obj2 )
            f = field.FieldInterface( double(obj1) .^ double(obj2) );
        end
        
        function f = lt( obj1, obj2 )
            f = field.FieldInterface( double(obj1) < double(obj2) );
        end
        
        function f = gt( obj1, obj2 )
            f = field.FieldInterface( double(obj1) > double(obj2) );
        end
        
        function f = le( obj1, obj2 )
            f = field.FieldInterface( double(obj1) <= double(obj2) );
        end
        
        function f = ge( obj1, obj2 )
            f = field.FieldInterface( double(obj1) >= double(obj2) );
        end
        
        function f = ne( obj1, obj2 )
            f = field.FieldInterface( double(obj1) ~= double(obj2) );
        end
        
        function f = eq( obj1, obj2 )
            f = field.FieldInterface( double(obj1) == double(obj2) );
        end
        
        function f = and( obj1, obj2 )
            f = field.FieldInterface( double(obj1) & double(obj2) );
        end
        
        function f = or( obj1, obj2 )
            f = field.FieldInterface( double(obj1) | double(obj2) );
        end
        
        function f = not( obj )
            f = field.FieldInterface( ~double(obj) );
        end
        
        function varargout = subsref( obj, subs )
            switch subs( 1 ).type
                case '.'
                    [varargout{1:nargout}] = builtin('subsref',obj,subs);
                case '()'
                    [varargout{1:nargout}] = builtin('subsref',double(obj),subs);
                case '{}'
                    assert( false );
                otherwise
                    assert( false );
            end
        end
        
        function obj = subsasgn( obj, subs, varargin )
            switch subs( 1 ).type
                case '.'
                    obj = builtin('subsasgn',obj,subs,varargin{:});
                case '()'
                    obj = builtin('subsasgn',double(obj),subs,varargin{:});
                case '{}'
                    assert( false );
                otherwise
                    assert( false );
            end
        end
        
    end
    
    
    properties ( Access = private )
        values
    end
    
end

