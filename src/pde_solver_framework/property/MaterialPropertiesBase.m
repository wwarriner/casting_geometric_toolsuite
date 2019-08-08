classdef (Abstract) MaterialPropertiesBase < handle
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint32
        ids(:,1) uint32
    end
    
    methods
        function has = has( obj, id )
            assert( isa( id, "uint32" ) );
            assert( isscalar( id ) );
            
            has = obj.materials.isKey( id );
        end
        
        function add( obj, material )
            assert( ~obj.has( material.id ) );
            
            obj.materials( material.id ) = material;
        end
        
        function ready = is_ready( obj )
            ready = true;
            for i = 1 : obj.count
                m = obj.materials( obj.ids( i ) );
                ready = ready & m.is_ready();
            end
        end
        
        function v = lookup( obj, id, property_name, varargin )
            assert( obj.has( id ) );
            
            v = obj.materials( id ).lookup( property_name, varargin{ : } );
        end
        
        function v = reduce( obj, id, property_name, fn )
            assert( obj.has( id ) );
            
            v = obj.materials( id ).reduce( property_name, fn );
        end
        
        function value = get.count( obj )
            value = obj.materials.Count;
        end
        
        function value = get.ids( obj )
            value = cell2mat( obj.materials.keys() );
        end
    end
    
    properties ( Access = protected )
        materials containers.Map
    end
    
    methods ( Access = protected )
        function obj = MaterialPropertiesBase()
            obj.materials = containers.Map( ...
                'keytype', 'uint32', ...
                'valuetype', 'any' ...
                );
        end
    end
    
end

