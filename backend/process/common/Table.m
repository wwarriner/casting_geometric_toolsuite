classdef Table < handle
    
    methods ( Access = public, Sealed )
        
        function t = to_table( obj, names_prefix )
            
            if nargin < 2
                names_prefix = [];
            end
            v = obj.get_table_values();
            n = obj.get_prefixed_table_names( names_prefix );
            assert( size( v, 2 ) == size( n, 2 ) );
            t = cell2table( v, 'VariableNames', n );
            
        end
        
        
        function s = to_summary( obj, names_prefix )
            
            if nargin < 2
                names_prefix = [];
            end
            s = obj.to_table();
            if obj.is_summarized()
                s = grpstats( s, {}, {'mean','std','min','max','range','meanci'} );
            end
            s.Properties.VariableNames = ...
                obj.prefix_names( s.Properties.VariableNames, names_prefix );
            
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
    
    
    methods ( Access = private )
        
        function names = get_prefixed_table_names( obj, prefix )
            
            names = obj.prefix_names( obj.get_table_names(), prefix );
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function names = prefix_names( names, prefix )
            
            if ~isempty( prefix )
                names = cellfun( ...
                    @(x) [ prefix '_' x ], ...
                    names, ...
                    'uniformoutput', false ...
                    );
            end
            
        end
        
    end
    
end

