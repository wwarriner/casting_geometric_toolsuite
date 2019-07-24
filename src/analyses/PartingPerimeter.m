classdef PartingPerimeter < handle
    
    properties ( SetAccess = private )
        projected(1,1) ProjectedPerimeter
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint64
        label_array(:,:,:) uint64
        binary_array(:,:,:) logical
        jog_free(1,1) JogFreePerimeter
        line(1,1) PartingLine
    end
    
    methods
        function obj = PartingPerimeter( interior )
            if nargin == 0
                return;
            end
            
            pp = ProjectedPerimeter( interior );
            [ bounds, height ] = compute_bounds( interior );
            bounds( ~repmat( pp.binary_array, [ 1 1 2 ] ) ) = 0;
            perimeter = unproject( bounds, height );
            label_array = repmat( pp.label_array, [ 1 1 height ] );
            label_array( ~perimeter ) = 0;
            obj.cc = label2cc( label_array );
            obj.bounds = bounds;
            obj.height = height;
            obj.projected = pp;
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
        
        function value = get.jog_free( obj )
            value = JogFreePerimeter( ...
                obj.projected, ...
                obj.bounds, ...
                obj.height ...
                );
        end
        
        function value = get.line( obj )
            value = PartingLine( ...
                obj.projected, ...
                obj.bounds, ...
                obj.height ...
                );
        end
    end
    
    properties ( Access = private )
        cc(1,1) struct
        bounds(:,:,2) uint64
        height(1,1) uint64
    end
    
end

