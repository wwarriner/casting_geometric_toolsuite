classdef DynamicPropertyTree < dynamicprops & matlab.mixin.CustomDisplay
    
    methods
        function obj = DynamicPropertyTree( varargin )
            if nargin == 0
                return;
            elseif nargin == 1
                obj.build( varargin{ 1 }, string( mfilename( 'class' ) ) );
            elseif nargin == 2
                obj.build( varargin{ 1 }, varargin{ 2 } );
            else
                assert( false );
            end
        end
        
        function s = struct( obj )
            s = struct();
            fields = string( fieldnames( obj ) );
            child_count = numel( fields );
            for i = 1 : child_count
                key = fields( i );
                value = obj.(key);
                if isobject( value )
                    value = value.struct();
                end
                s.(key) = value;
            end
        end
        
        function varargout = subsref( obj, s )
            switch s(1).type
                case '.'
                    if 1 < length( s ) && ~strcmpi( s( 2 ).type, '.' )
                        % function calls
                        [ varargout{ 1 : nargout } ] = builtin( 'subsref', obj, s );
                    else
                        % property access
                        key = s( 1 ).subs;
                        if ~isprop( obj, key )
                            error( obj.missing_msg( key ) );
                        end
                        v = obj.(key);
                        if length( s ) == 1
                            [ varargout{ 1 : nargout } ] = v;
                        else
                            [ varargout{ 1 : nargout } ] = subsref( v, s( 2 : end ) );
                        end
                    end
                case '()'
                    [ varargout{ 1 : nargout } ] = builtin( 'subsref', obj, s );
                case '{}'
                    [ varargout{ 1 : nargout } ] = builtin( 'subsref', obj, s );
                otherwise
                    assert( false );
            end
        end
        
        function obj = subsasgn( obj, s, varargin )
            switch s(1).type
                case '.'
                    % property access
                    key = s( 1 ).subs;
                    if ~isprop( obj, key )
                        error( obj.missing_msg( key ) );
                    end
                    if length( s ) == 1
                        v = varargin{ : };
                    else
                        v = subsasgn( obj.(key), s( 2 : end ), varargin{ : } );
                    end
                    obj.(key) = v;
                case '()'
                    builtin( 'subsasgn', obj, varargin{ : } );
                case '{}'
                    builtin( 'subsasgn', obj, s, varargin{ : } );
                otherwise
                    assert( false );
            end
        end
        
        function value = properties( obj )
            if nargout == 0
                disp( builtin( "properties", obj ) );
            else
                value = sort( builtin( "properties", obj ) );
            end
        end
        
        function value = fieldnames( obj )
            value = sort( builtin( "fieldnames", obj ) );
        end
        
        function addprop( obj, varargin )
            if obj.is_mutable()
                addprop@dynamicprops( obj, varargin{ : } );
            else
                me = error( "Adding properties is not allowed." );
                throwAsCaller( me );
            end
        end
    end
    
    methods ( Access = protected )
        function build( obj, s, type )
            assert( obj.is_mutable() );
            
            assert( isstruct( s ) );
            
            assert( isstring( type ) );
            
            fields = string( fieldnames( s ) );
            child_count = numel( fields );
            for i = 1 : child_count
                key = fields( i );
                value = s.(key);
                if isstruct( value )
                    child = feval( type );
                    child.build( value, type );
                    value = child;
                end
                obj.addprop( key );
                obj.(key) = value;
            end
            
            obj.remove_mutability();
        end
        
        function group = getPropertyGroups( obj )
            props = properties( obj );
            group = matlab.mixin.util.PropertyGroup( props );
        end
        
        function mutable = is_mutable( obj )
            mutable = obj.is_mutable____;
        end
        
        function remove_mutability( obj )
            obj.is_mutable____ = false;
        end
    end
    
    methods ( Access = protected, Static )
        function value = missing_msg( key )
            value = sprintf( "Missing setting: %s\n", key );
        end
    end
    
    properties ( Access = private )
        is_mutable____(1,1) logical = true
    end
    
end

