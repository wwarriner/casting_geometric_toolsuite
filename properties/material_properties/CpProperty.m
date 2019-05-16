classdef (Sealed) CpProperty < MaterialProperty
    
    methods ( Access = public )
        
        % units are J / kg * K
        
        function q = compute_q_property( obj, t_range )
            
            q = QProperty( obj, t_range );
            
        end
        
    end
    
end

