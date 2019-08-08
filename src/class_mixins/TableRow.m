classdef TableRow < handle
    
    methods ( Access = public )
        
        function count = get_table_row_length( obj )
            
            count = numel( obj.get_table_row_names() );
            
        end
        
    end
    
    
    methods ( Access = public, Abstract )
        
        tr = to_table_row( obj );
        
    end
    
    
    methods ( Access = public, Static, Abstract )
        
        trn = get_table_row_names();
        
    end
    
end

