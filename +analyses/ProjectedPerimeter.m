classdef ProjectedPerimeter < handle
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint64
        label_array(:,:) uint64
        binary_array(:,:) logical
    end
    
    methods
        function obj = ProjectedPerimeter( interior )
            if nargin == 0
                return;
            end
            
            projected = project( interior );
            perimeter = bwperim( projected );
            obj.cc = bwconncomp( perimeter );
        end
        
        function value = get.count( obj )
            value = obj.cc.NumObjects;
        end
        
        function value = get.label_array( obj )
            value = labelmatrix( obj.cc );
        end
        
        function value = get.binary_array( obj )
            value = obj.label_array > 0;
        end
    end
    
    properties ( Access = private )
        cc(1,1) struct
    end
    
end

