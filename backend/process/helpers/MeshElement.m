classdef ( Sealed ) MeshElement < ProcessHelper
    
    properties ( GetAccess = public, SetAccess = private )
        
        volume;
        length;
        area;
        
    end
    
    methods ( Access = public )
        
        function obj = MeshElement( desired_element_count, MeshEnvelope )
            
            obj.volume = MeshEnvelope.volume ./ desired_element_count;
            obj.length = obj.volume .^ ( 1.0 / 3.0 );
            obj.area = obj.length .^ 2.0;
            
        end
        
        
        function tr = to_table_row( obj )
            
            tr = {...
                obj.length ...
                obj.area ...
                obj.volume ...
                };
            assert( numel( tr ) == obj.get_table_row_length() );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function trn = get_table_row_names()
            
            trn = { 'length', 'area', 'volume' };
            
        end
        
    end
    
end

