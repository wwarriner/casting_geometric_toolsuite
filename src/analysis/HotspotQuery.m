classdef HotspotQuery < handle
    
    properties ( SetAccess = private, Dependent )
        count(1,1) double
        label_array(:,:,:) uint32
    end
    
    methods
        function obj = HotspotQuery( segments, filtered_profile )
            if nargin == 0
                return;
            end
            
            assert( ndims( segments ) == 3 );
            assert( isa( segments, 'uint32' ) );
            
            assert( ndims( filtered_profile ) == 3 );
            assert( isa( filtered_profile, 'double' ) );
            assert( isreal( filtered_profile ) );
            assert( all( isfinite( filtered_profile ), 'all' ) );
            
            hotspots = imregionalmax( filtered_profile );
            segments( ~hotspots ) = 0;
            obj.cc = label2cc( segments );
        end
        
        function value = get.count( obj )
            value = obj.cc.NumObjects;
        end
        
        function value = get.label_array( obj )
            value = uint32( labelmatrix( obj.cc ) );
        end
    end
    
    properties ( Access = private )
        cc(1,1) struct
    end
    
end

