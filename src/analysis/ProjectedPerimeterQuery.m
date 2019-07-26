classdef ProjectedPerimeterQuery < handle
    
    properties ( SetAccess = private )
        area(1,1) double % mesh units
        length(1,1) double % mesh units
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint64
        label_array(:,:) uint64
        binary_array(:,:) logical
    end
    
    methods
        function obj = ProjectedPerimeterQuery( interior )
            if nargin == 0
                return;
            end
            
            projected = project( interior );
            area = sum( projected, 'all' );
            perimeter = bwperim( projected );
            length = sum( perimeter, 'all' );
            cc = bwconncomp( perimeter );
            cc.NumObjects = uint64( cc.NumObjects );
            obj.cc = cc;
            obj.area = area;
            obj.length = length;
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

