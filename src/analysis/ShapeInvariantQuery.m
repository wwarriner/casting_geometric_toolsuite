classdef ShapeInvariantQuery < handle
    % @ShapeInvariantQuery determines dimensionless global shape invariant
    % information from a @Body.
    % - @body is a @Body object.
    
    properties
        hole_count(1,1) double {mustBeReal,mustBeFinite}
        flatness(1,1) double {mustBeReal,mustBeFinite}
        ranginess(1,1) double {mustBeReal,mustBeFinite}
        solidity(1,1) double {mustBeReal,mustBeFinite}
        bounding_sphere_diameter(1,1) double {mustBeReal,mustBeFinite}
        convex_volume(1,1) double {mustBeReal,mustBeFinite}
    end
    
    methods
        function obj = ShapeInvariantQuery( body )
            assert( isscalar( body ) );
            assert( isa( body, 'Body' ) );
            
            hole_count = count_holes( body.fv );
            cfv = body.convex_hull_fv;
            cfv_volume = compute_fv_volume( cfv );
            radius = obj.compute_bounding_sphere_radius( cfv );
            flatness = obj.compute_flatness( radius, cfv_volume );
            ranginess = obj.compute_ranginess( body.surface_area, body.volume );
            solidity = obj.compute_solidity( body.volume, cfv_volume );
            
            obj.hole_count = hole_count;
            obj.flatness = flatness;
            obj.ranginess = ranginess;
            obj.solidity = solidity;
            obj.bounding_sphere_diameter = 2 .* radius;
            obj.convex_volume = cfv_volume;
        end
    end
    
    methods ( Access = private, Static )
        function radius = compute_bounding_sphere_radius( convex_hull_fv )
            [ ~, radius ] = minboundsphere( ...
                convex_hull_fv.vertices, ...
                convex_hull_fv.faces ...
                );
        end
        
        function flatness = compute_flatness( ...
                bounding_sphere_radius, ...
                convex_hull_volume ...
                )
            
            bounding_sphere_volume = ( 4 * pi / 3 ) * ( bounding_sphere_radius ^ 3 );
            flatness = 1 - ( convex_hull_volume ./ bounding_sphere_volume );
        end
        
        function ranginess = compute_ranginess( surface_area, volume )
            % coefficient sets raw ranginess of sphere to 0
            % sphere has minimal sa/vol ratio, max is inf, so range is 0 to 1
            COEFF = ( 36 * pi ) ^ ( 1 / 3 );
            nsa = surface_area / ( volume ^ ( 2/3 ) );
            ranginess = 1 - ( COEFF / nsa );
        end
        
        function solidity = compute_solidity( volume, convex_hull_volume )
            solidity = volume ./ convex_hull_volume;
        end
    end
    
end

