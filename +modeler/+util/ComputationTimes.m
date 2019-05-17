classdef ComputationTimes < handle
    
    methods ( Access = public )
        
        function obj = ComputationTimes( variables )
            
            obj.count = numel( variables );
            obj.data = array2table( ...
                zeros( 0, obj.count ), ...
                'variablenames', variables ...
                );
            
        end
        
        
        function add_row( obj )
            
            obj.data{ end + 1, : } = zeros( 1, obj.count );
            
        end
        
        
        function append_times( obj, var, times )
            
            obj.data{ end, var } = times;
            
        end
        
        
        function summary = summarize( obj )
            
            summary = varfun( @sum, obj.data );
            
        end
        
        
        function total = get_total( obj )
            
            summary = obj.summarize();
            total = sum( summary{ :, : } );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        count
        data
        
    end
    
end

