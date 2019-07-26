classdef PartingPerimeterQuery < handle
    
    properties ( SetAccess = private )
        projected ProjectedPerimeterQuery
        jog_free JogFreePerimeterQuery
        line PartingLineQuery
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint32
        label_array(:,:,:) uint32
        binary_array(:,:,:) logical
    end
    
    methods
        function obj = PartingPerimeterQuery( interior )
            if nargin == 0
                return;
            end
            
            pp = ProjectedPerimeterQuery( interior );
            
            [ bounds, height ] = compute_bounds( interior );
            bounds( ~repmat( pp.binary_array, [ 1 1 2 ] ) ) = 0;
            
            label_array = repmat( pp.label_array, [ 1 1 height ] );
            perimeter = unproject( bounds, height );
            label_array( ~perimeter ) = 0;
            
            jf = JogFreePerimeterQuery( pp, bounds, height );
            pl = PartingLineQuery( pp, bounds, height );
            
            obj.cc = label2cc( label_array );
            obj.projected = pp;
            obj.jog_free = jf;
            obj.line = pl;
        end
        
        function value = get.count( obj )
            value = uint32( obj.cc.NumObjects );
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
    
end

