classdef Interface < handle
    
    methods
        function obj = Interface()
            obj.interface_properties = containers.Map( ...
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
            
            has = obj.interface_properties.isKey( first_id );
            if has
                m = obj.interface_properties( first_id );
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
            
            if obj.interface_properties.isKey( first_id )
                m = obj.interface_properties( first_id );
                assert( ~m.isKey( second_id ) );
            else
                m = containers.Map( ...
                    'keytype', 'uint32', ...
                    'valuetype', 'any' ...
                    );
                obj.interface_properties( first_id ) = m;
            end
            m( second_id ) = property; %#ok<NASGU>
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
        interface_properties containers.Map
    end
    
    methods ( Access = private )
        function p = get( obj, first_id, second_id )
            assert( obj.has( first_id, second_id ) );
            
            [ first_id, second_id ] = obj.prepare_ids( first_id, second_id );
            
            m = obj.interface_properties( first_id );
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

