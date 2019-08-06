classdef InterfaceProperties < handle
    
    methods
        function obj = InterfaceProperties()
            obj.props = containers.Map( ...
                'keytype', 'uint32', ...
                'valuetype', 'any' ...
                );
        end
        
        function has = has( obj, first_id, second_id )
            assert( isa( first_id, 'uint32' ) );
            assert( isscalar( first_id ) );
            
            assert( isa( second_id, 'uint32' ) );
            assert( isscalar( second_id ) );
            assert( first_id ~= second_id );
            
            [ first_id, second_id ] = obj.prepare_ids( first_id, second_id );
            
            has = obj.props.isKey( first_id );
            if has
                m = obj.props( first_id );
                has = m.isKey( second_id );
            end
        end
        
        function add( obj, first_id, second_id, property )
            assert( isa( first_id, 'uint32' ) );
            assert( isscalar( first_id ) );
            
            assert( isa( second_id, 'uint32' ) );
            assert( isscalar( second_id ) );
            assert( first_id ~= second_id );
            
            assert( isa( property, 'PropertyInterface' ) );
            
            [ first_id, second_id ] = obj.prepare_ids( first_id, second_id );
            
            if obj.props.isKey( first_id )
                m = obj.props( first_id );
                assert( ~m.isKey( second_id ) );
            else
                m = containers.Map( ...
                    'keytype', 'uint32', ...
                    'valuetype', 'any' ...
                    );
                obj.props( first_id ) = m;
            end
            m( second_id ) = property; %#ok<NASGU>
        end
        
        % @expected_ids is a uint32 vector of ids that exist in the mesh
        function complete = is_ready( obj, expected_ids )
            complete = true;
            count = numel( expected_ids );
            for i = 1 : count
                for j = i + 1 : count
                    if ~obj.has( expected_ids( i ), expected_ids( j ) )
                        complete = false;
                        return;
                    end
                end
            end
        end
        
        function v = lookup( obj, first_id, second_id, varargin )
            assert( isa( first_id, 'uint32' ) );
            assert( isscalar( first_id ) );
            
            assert( isa( second_id, 'uint32' ) );
            assert( isscalar( second_id ) );
            assert( first_id ~= second_id );
            
            p = obj.get( first_id, second_id );
            v = p.lookup( varargin{ : } );
        end
        
        function v = reduce( obj, first_id, second_id, fn )
            assert( isa( first_id, 'uint32' ) );
            assert( isscalar( first_id ) );
            
            assert( isa( second_id, 'uint32' ) );
            assert( isscalar( second_id ) );
            assert( first_id ~= second_id );
            
            p = obj.get( first_id, second_id );
            v = p.reduce( fn );
        end
    end
    
    properties ( Access = private )
        props containers.Map
    end
    
    methods ( Access = private )
        function p = get( obj, first_id, second_id )
            assert( obj.has( first_id, second_id ) );
            
            [ first_id, second_id ] = obj.prepare_ids( first_id, second_id );
            
            m = obj.props( first_id );
            p = m( second_id );
        end
    end
    
    methods ( Access = private, Static )
        function [ first, second ] = prepare_ids( first, second )
            ids = sort( [ first second ] ) + 1;
            first = ids( 1 );
            second = ids( 2 );
        end
    end
    
end

