classdef MaterialBase < handle
    
    properties
        id(1,1) uint32
    end
    
    methods ( Abstract )
        ready = is_ready( obj )
    end
    
    methods
        function has = has( obj, key )
            assert( isstring( key ) );
            assert( isscalar( key ) );
            
            key = char( key );
            has = obj.material_properties.isKey( key );
        end
        
        function add( obj, property )
            assert( isa( property, 'PropertyInterface' ) );
            assert( ~obj.material_properties.isKey( property.name ) );
            
            obj.material_properties( char( property.name ) ) = property;
        end
        
        function v = lookup( obj, key, varargin )
            assert( isstring( key ) );
            assert( isscalar( key ) );
            
            p = obj.get( key );
            v = p.lookup( varargin{ : } );
        end
        
        function v = reduce( obj, key, fn )
            assert( isstring( key ) );
            assert( isscalar( key ) );
            
            p = obj.get( key );
            v = p.reduce( fn );
        end
    end
    
    methods ( Access = protected )
        function obj = MaterialBase()
            obj.material_properties = containers.Map( ...
                'keytype', 'char', ...
                'valuetype', 'any' ...
                );
        end
        
        function p = get( obj, key )
            assert( isstring( key ) );
            assert( isscalar( key ) );
            
            key = char( key );
            p = obj.material_properties( key );
        end
    end
    
    properties ( Access = private )
        material_properties containers.Map
    end
    
end

