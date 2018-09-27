classdef Table < handle
    
    methods ( Access = public, Sealed )
        
        function t = to_table( obj )
            
            v = obj.get_table_values();
            n = obj.get_table_names();
            assert( size( v, 2 ) == size( n, 2 ) );
            t = cell2table( v, 'VariableNames', n );
            
        end
        
        
        function s = to_summary( obj )
            
            s = obj.to_table();
            if obj.is_summarized()
                s = grpstats( s, {}, {'mean','std','min','max','range','meanci'} );
            end
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function names = get_table_names( ~ )
            
            names = {};
            
        end
        
        
        function values = get_table_values( ~ )
            
            values = {};
            
        end
        
        
        % change to true for classes which use process helpers
        function summarized = is_summarized( ~ )
            
            summarized = false;
            
        end
        
    end
    
end

