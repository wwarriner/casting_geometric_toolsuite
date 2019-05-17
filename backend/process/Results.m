classdef (Sealed) Results < handle
    
    properties ( Access = private )
        
        options
        results
        
    end
    
    
    methods ( Access = public )
        
        function obj = Results( options )
            
            obj.results = containers.Map( ...
                'keytype', 'char', ...
                'valuetype', 'any' ...
                );
            obj.options = options;
            
        end
        
        
        function add( obj, process_key, result )
            
            obj.results( process_key.to_string() ) = result;
            
        end
        
        
        function exist = exists( obj, process_key )
            
            exist = isKey( obj.results, process_key.to_string() );
            
        end
        
        
        function result = get( obj, process_key )
            
            key = process_key.to_string();
            if obj.exists( process_key )
                result = obj.results( key );
            else
                assert( ~isempty( obj.options ) );
                result = process_key.create_instance( obj, obj.options );
                result.run();
                obj.results( key ) = result;
            end
            
        end
        
        
        function results = get_all( obj )
            
            results = obj.results.values();
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function exist = exists_raw_key( obj, raw_key )
            
            exist = isKey( obj.results, raw_key );
            
        end
        
        
        function result = get_by_raw_key( obj, raw_key )
            
            result = obj.results( raw_key );
            
        end
        
        
        function keyset = get_raw_keys( obj )
            
            keyset = keys( obj.results );
            
        end
        
        
        function count = get_count( obj )
            
            count = obj.results.Count;
            
        end
        
    end
    
end

