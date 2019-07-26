classdef ShapeQuery < handle
    % @ShapeQuery determines global shape information from a face-vertex struct
    % and its corresponding convex hull. Note that client code must ensure that
    % @convex_hull is the convex hull of @fv.
    % Inputs:
    % - @fv is a scalar struct containing data for a face-vertex geometry
    % representation in the standard MATLAB style.
    % - @convex_hull is a ConvexHull object corresponding to @fv.
    
    properties
        surface_area(1,1) double {mustBeReal,mustBeFinite}
        volume(1,1) double {mustBeReal,mustBeFinite}
        hole_count(1,1) double {mustBeReal,mustBeFinite}
        flatness(1,1) double {mustBeReal,mustBeFinite}
        ranginess(1,1) double {mustBeReal,mustBeFinite}
        solidity(1,1) double {mustBeReal,mustBeFinite}
        centroid(1,:) double {mustBeReal,mustBeFinite}
    end
    
    methods
        function obj = ShapeQuery( fv, convex_hull )
            assert( isstruct( fv ) );
            assert( isfield( fv, 'faces' ) );
            assert( isfield( fv, 'vertices' ) );
            
            assert( isscalar( convex_hull ) );
            assert( isa( convex_hull, 'ConvexHull' ) );
            
            [ volume, centroid ] = compute_fv_volume( fv );
            triangle_areas = compute_triangle_areas( fv );
            surface_area = sum( triangle_areas );
            
            hole_count = count_holes( fv );
            flatness = obj.compute_flatness( fv.vertices, conv_fv, conv_volume );
            ranginess = obj.compute_ranginess( surface_area, volume );
            solidity = obj.compute_solidity( volume, conv_volume );
            
            obj.surface_area = surface_area;
            obj.volume = volume;
            obj.hole_count = hole_count;
            obj.flatness = flatness;
            obj.ranginess = ranginess;
            obj.solidity = solidity;
            obj.centroid = centroid;
        end
    end
    
    methods ( Access = private )
        function flatness = compute_flatness( ...
                vertices, ...
                convex_hull_fv, ...
                convex_hull_volume ...
                )
            [ ~, r ] = minboundsphere( vertices, convex_hull_fv.faces );
            bounding_sphere_volume = ( 4 * pi / 3 ) * ( r ^ 3 );
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

