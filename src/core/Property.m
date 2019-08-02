classdef Property < dynamicprops
    
    methods ( Access = public )
        
        function add( obj, key, value )
            
            key = char( key );
            
            if isempty( key ); return; end
            
            [ first, rest ] = obj.split( key );
            if isprop( obj, first ) && ~isempty( rest )
                obj.(first).add( rest, value );
            else
                p = obj.addprop( first );
                if isempty( rest )
                    sub = value;
                else
                    sub = Property();
                    sub.add( rest, value );
                end
                obj.(first) = sub;
                p.GetAccess = 'public';
                p.SetAccess = 'private';
            end
            
        end
        
        
        function set( obj, key, value )
            
            key = char( key );
            
            obj.set_impl( key, key, value );
            
        end
        
        
        function value = get( obj, key, fallback )
            
            key = char( key );
            
            if nargin < 3
                fallback = [];
            end
            
            % TODO improve fallback
            value = obj.get_impl( key, key );
            if ~isempty( fallback ) && isempty( value )
                value = fallback;
            end
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function set_impl( obj, full_key, key, value )
            
            assert( ~isempty( key ) );
            
            [ first, rest ] = obj.split( key );
            if ~isprop( obj, first )
                warning( 'Cannot set unknown key: %s\n', full_key );
                return;
            end
            
            if isempty( rest )
                if isa( obj.(first), 'Property' )
                    warning( 'Cannot overwrite subproperty: %s\n', full_key );
                    return;
                else
                    obj.(first) = value;
                end
            else
                if ~isa( obj.(first), 'Property' )
                    warning( 'Cannot overwrite value: %s\n', full_key );
                    return;
                else
                    obj.(first).set_impl( full_key, rest, value );
                end
            end
            
        end
        
        
        function value = get_impl( obj, full_key, key )
            
            assert( ~isempty( key ) );
            
            [ first, rest ] = obj.split( key );
            if ~isprop( obj, first )
                warning( 'Cannot get unknown key: %s\n', full_key );
                value = [];
                return;
            end
            
            if isempty( rest )
                value = obj.(first);
            else
                value = obj.(first).get_impl( full_key, rest );
            end
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function [ first, rest ] = split( key )
            
            first = extractBefore( key, '.' );
            if isempty( first ); first = key; end
            if ~isvarname( first )
                error( 'Invalid key: %s\n', char( first ) );
            end
            rest = extractAfter( key, '.' );
            
        end
        
    end
    
end

