classdef PartingPerimeter < handle
    
    properties ( SetAccess = private )
        projected(1,1) ProjectedPerimeter
        jog_free(1,1) JogFreePerimeter
        line(1,1) PartingLine
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint64
        label_array(:,:,:) uint64
        binary_array(:,:,:) logical
    end
    
    methods
        function obj = PartingPerimeter( interior )
            if nargin == 0
                return;
            end
            
            pp = ProjectedPerimeter( interior );
            
            [ bounds, height ] = compute_bounds( interior );
            bounds( ~repmat( pp.binary_array, [ 1 1 2 ] ) ) = 0;
            
            label_array = repmat( pp.label_array, [ 1 1 height ] );
            perimeter = unproject( bounds, height );
            label_array( ~perimeter ) = 0;
            
            jf = JogFreePerimeter( pp, bounds, height );
            pl = PartingLine( pp, bounds, height );
            
            obj.cc = label2cc( label_array );
            obj.projected = pp;
            obj.jog_free = jf;
            obj.line = pl;
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

