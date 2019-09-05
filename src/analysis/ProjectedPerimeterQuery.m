classdef ProjectedPerimeterQuery < handle
    
    properties ( SetAccess = private )
        area(1,1) double % mesh units
        length(1,1) double % mesh units
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) double
        label_array(:,:) uint32
        binary_array(:,:) logical
    end
    
    methods
        function obj = ProjectedPerimeterQuery( interior )
            if nargin == 0
                return;
            end
            
            projected = obj.project_area( interior );
            area = sum( projected, 'all' );
            perimeter = bwperim( projected );
            length = sum( perimeter, 'all' );
            cc = bwconncomp( perimeter );
            obj.cc = cc;
            obj.area = area;
            obj.length = length;
        end
        
        function value = get.count( obj )
            value = obj.cc.NumObjects;
        end
        
        function value = get.label_array( obj )
            value = uint32( labelmatrix( obj.cc ) );
        end
        
        function value = get.binary_array( obj )
            value = obj.label_array > 0;
        end
    end
    
    properties ( Access = private )
        cc(1,1) struct
    end
    
    methods ( Access = private )
        function projected = project_area( obj, interior )
            projected = project( interior );
            projected = ~bwareaopen( ~projected, obj.PIXEL_COUNT_TO_REMOVE + 1 );
        end
    end
    
    properties ( Access = private, Constant )
        PIXEL_COUNT_TO_REMOVE = 4
    end
    
end

