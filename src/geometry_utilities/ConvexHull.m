classdef ConvexHull < handle
    
    properties
        fv
        volume
    end
    
    methods
        function obj = ConvexHull( fv )
            cfv = compute_convex_hull( fv );
            volume = compute_fv_volume( cfv );
            obj.fv = cfv;
            obj.volume = volume;
        end
    end
    
end

