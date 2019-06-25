classdef (Abstract) KernelInterface < handle
    
    methods ( Access = public )
        
        A = create_coefficient_matrix( obj );
        b = create_constant_vector( obj );
        
    end
    
end

