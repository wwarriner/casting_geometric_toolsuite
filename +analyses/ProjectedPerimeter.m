classdef ProjectedPerimeter < handle
    
    properties ( GetAccess = public, SetAccess = private, Dependent )
        count
        label_matrix
        perimeter
    end
    
    methods ( Access = public )
        
        function obj = ProjectedPerimeter( projected_interior )
            if nargin == 0
                return;
            end
            
            assert( ismatrix( projected_interior ) );
            assert( islogical( projected_interior ) );
            
            perimeter = obj.determine_perimeter( projected_interior );
            obj.values = obj.label( perimeter );
        end
        
    end
    
    
    methods % getters
        
        function value = get.count( obj )
            value = uint64( numel( unique( obj.values ) ) - 1 );
        end
        
        function value = get.label_matrix( obj )
            value = obj.values;
        end
        
        function value = get.perimeter( obj )
            value = obj.values > 0;
        end
        
    end
    
    
    properties ( Access = private )
        image(:,:) logical = []
        values(:,:) double {mustBeReal,mustBeFinite,mustBeNonnegative} = []
    end
    
    
    methods ( Access = private, Static )
        
        function perimeter = determine_perimeter( image )
            perimeter = bwperim( image, conndef( 2, 'minimal' ) );
        end
        
        function labels = label( perimeter )
            labels = labelmatrix( bwconncomp( ...
                perimeter, ...
                conndef( 2, 'maximal' ) ...
                ) );
        end
        
    end
    
end

