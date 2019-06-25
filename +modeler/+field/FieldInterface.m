classdef (Abstract) FieldInterface < handle
    
    methods ( Access = public )
        
        % - returns true if and only if each N-D element has dimension 1
        is = is_scalar( obj );
        
        % - returns true if and only if each N-D element has dimension 2
        is = is_vector( obj );
        
        % - returns true if and only if each N-D element has dimension greater
        % than 2
        is = is_tensor( obj );
        
        % - if field is scalar, returns N-D array
        % - if field is vector or tensor, returns (N+1)-D array
        % - use get_tensor_shape() to transform values at each N-D location
        values = get( obj );
        
        % - if field is_scalar(), returns 1
        % - if field is_vector(), returns scalar greater than 1
        % - if field is_tensor(), returns vector with numel() greater than 1
        % - used to reshape values at each N-D location
        shape = get_tensor_shape( obj );
        
        % - used to update the values contained in the field
        % - subclasses should use this to set individual values
        % - use the subclass constructor to inject dependencies
        update( obj );
        
    end
    
end

