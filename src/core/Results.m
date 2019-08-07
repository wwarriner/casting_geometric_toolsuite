classdef (Sealed) Results < handle
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint32
    end
    
    methods
        function obj = Results( settings )
            obj.results = containers.Map( ...
                'keytype', 'char', ...
                'valuetype', 'any' ...
                );
            obj.settings = settings;
        end
        
        function add( obj, process_key, result )
            assert( ~obj.exists( process_key ) );
            
            obj.results( process_key.name ) = result;
        end
        
        function exist = exists( obj, process_key )
            exist = obj.results.isKey( process_key.name );
        end
        
        function result = get( obj, process_key )
            if obj.exists( process_key )
                result = obj.results( process_key.name );
            else
                result = process_key.create_instance( obj, obj.settings );
                result.run();
                obj.results( process_key.name ) = result;
            end
        end
        
        function value = get.count( obj )
            value = uint32( obj.results.Count );
        end
    end
    
    properties ( Access = private )
        settings Settings
        results containers.Map
    end
    
end

