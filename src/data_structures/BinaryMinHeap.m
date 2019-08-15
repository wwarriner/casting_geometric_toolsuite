classdef BinaryMinHeap < handle
    % @BinaryMinHeap is a typical implementation for a binary min heap, but does
    % not allow storage of arbitrary objects. Instead, only indices to some
    % unknown external container are stored. Priorities are not passed directly
    % when adding, instead a key function handle is given at construction
    % time which accepts an index and returns a double.
    %
    % Properties:
    % - @top is the real, finite, positive scalar double value associated with
    % the minimum key in the heap, used for peeking without popping.
    % - @empty is a scalar logical denoting if the heap is empty.
    % - @count is a real, finite, scalar double indicating how many elements are
    % on the heap.
    
    properties ( SetAccess = private, Dependent )
        top(1,1) double {mustBeReal,mustBeFinite} 
        empty(1,1) logical
        count(1,1) double {mustBeReal,mustBeFinite}
    end
    
    methods
        % Inputs:
        % - @key_value_fn is a scalar function handle with signature
        % v = @(x), where @x is a scalar index into the unknown external
        % container, and @v is a real, finite, scalar double value.
        % - @initial_size, optional, is a positive scalar uint32 which indicates
        % how large initial storage should be.
        function obj = BinaryMinHeap( key_value_fn, initial_size )
            if nargin < 2
                initial_size = 1000;
            end
            
            assert( isa( initial_size, "uint32" ) );
            assert( isscalar( initial_size ) );
            assert( 0 < initial_size );
            
            obj.v = nan( initial_size, 1 );
            obj.p = nan( initial_size, 1 );
            obj.m = containers.Map( ...
                "keytype", "double", ...
                "valuetype", "double" ...
                );
            obj.p_fn = key_value_fn;
            obj.last = 0;
        end
        
        % @add allows adding of indices to the heap.
        % Inputs:
        % - @v is a positive scalar uint32 index into some unknown external
        % container.
        function add( obj, v )
            assert( ~obj.exists( v ) )
            obj.last = obj.last + 1;
            obj.v( obj.last ) = v;
            obj.p( obj.last ) = obj.p_fn( v );
            obj.m( v ) = obj.last;
            obj.float( obj.last );
        end
        
        % @pop allows removal of the value associated with the minimum key of 
        % the heap.
        % Outputs:
        % - @v is a positive scalar uint32 index into some unknown external
        % container which has the minimum key.
        function v = pop( obj )
            if obj.empty
                assert( false );
            end
            v = obj.top;
            obj.swap( 1, obj.last );
            obj.v( obj.last ) = nan;
            obj.p( obj.last ) = nan;
            obj.m.remove( v );
            obj.last = obj.last - 1;
            obj.sink( 1 );
        end
        
        % @update allows updating the key associated with a value.
        % Inputs:
        % - @v is a positive scalar uint32 index into some unknown external
        % container.
        function update( obj, v )
            if obj.empty
                assert( false );
            end
            index = obj.m( v );
            p_old = obj.p( obj.m( v ) );
            p_new = obj.p_fn( v );
            obj.p( obj.m( v ) ) = p_new;
            if p_old < p_new
                obj.sink( index );
            elseif p_new < p_old
                obj.float( index );
            else % no change
                return;
            end                
        end
        
        % @exists determines if a value exists in the heap.
        % Inputs:
        % - @v is a positive scalar uint32 index into some unknown external
        % container.
        % Outputs:
        % - @e is a scalar logical indicating existence of @v.
        function e = exists( obj, v )
            e = obj.m.isKey( v );
        end
        
        function value = get.top( obj )
            if obj.empty
                assert( false );
            end
            value = obj.v( 1 );
        end
        
        function value = get.empty( obj )
            value = obj.count <= 0;
        end
        
        function value = get.count( obj )
            value = obj.last;
        end
    end
    
    properties ( Access = private )
        v(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        p(:,1) double {mustBeReal,mustBeFinite}
        m containers.Map
        p_fn(1,1) function_handle = @(x)x
        last(1,1) double {mustBeReal,mustBeFinite}
    end
    
    methods ( Access = private )
        % moves toward top element
        function float( obj, index )
            current = index;
            parent = fix( index / 2 );
            while 1 <= parent && obj.p( current ) < obj.p( parent )
                obj.swap( current, parent );
                current = parent;
                parent = fix( parent / 2);
            end
        end
        
        % moves away from top element
        function sink( obj, index )
            current = index;
            while true
                lhs_child = current * 2;
                if obj.last < lhs_child
                    break;
                end
                [ p_child, ind ] = min( [ ...
                    obj.p( lhs_child ) ...
                    obj.p( lhs_child + 1 ) ...
                    ] );
                if obj.p( current ) < p_child
                    break;
                end
                small_child = lhs_child + ind - 1;
                obj.swap( current, small_child );
                current = small_child;
            end
        end
        
        % exchanges two elements
        function swap( obj, lhs, rhs )
            [ obj.v( rhs ), obj.v( lhs ) ] = ...
                deal( obj.v( lhs ), obj.v( rhs ) );
            [ obj.p( rhs ), obj.p( lhs ) ] = ...
                deal( obj.p( lhs ), obj.p( rhs ) );
            obj.m( obj.v( lhs ) ) = lhs;
            obj.m( obj.v( rhs ) ) = rhs;
        end
        
        % validates the heap conditions
        % not used in practice, but useful for debugging
        function v = validate( obj, index )
            if nargin < 2
                index = 1;
            end
            if index > obj.count
                v = true;
                return;
            end
            v = obj.p( index ) < obj.validate( 2 * index ) ...
                && obj.p( index ) < obj.validate( 2 * index + 1 ) ...
                && obj.m( obj.v( index ) ) == index;
        end
    end
    
end

