classdef FeederQuery < handle
    % all in mesh units
    
    properties ( SetAccess = private )
        radius(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        magnitude(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        position(:,3) double {mustBeReal,mustBeFinite}
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint32
        fv(:,1) struct
        diameter(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        height(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        area(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        volume(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
    end
    
    methods
        function obj = FeederQuery( segments, hotspots, edt )
            stats = regionprops3( segments, "centroid" );
            position = vertcat( stats.Centroid );
            position( :, [ 1 2 ] ) = position( :, [ 2 1 ] ); % image x-y coordinates flipped
            [ radius, magnitude ] = ...
                obj.feeder_sfsa( segments, hotspots, edt );
            height_offset = obj.compute_height_offset( segments, edt );
            
            obj.position = position;
            obj.radius = radius;
            obj.magnitude = magnitude;
            obj.height_offset = height_offset;
        end
        
        function value = get.count( obj )
            value = numel( obj.magnitude );
        end
        
        function value = get.fv( obj )
            for i = 1 : obj.count
                value( i ) = obj.generate_fv( ...
                    obj.position( i, : ), ...
                    obj.radius( i ), ...
                    obj.height( i ) ...
                    ); %#ok<AGROW>
            end
        end
        
        function value = get.diameter( obj )
            value = obj.radius .* 2;
        end
        
        function value = get.height( obj )
            value = obj.HEIGHT_DIAMETER_RATIO .* obj.diameter + obj.height_offset;
        end
        
        function value = get.area( obj )
            value = pi .* ( obj.radius .^ 2 );
        end
        
        function value = get.volume( obj )
            value = obj.area .* obj.height;
        end
    end
    
    properties ( Access = private )
        height_offset(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
    end
    
    methods ( Access = private )
        function [ radius, magnitude ] = feeder_sfsa( obj, segments, hotspots, edt )
            VOLUME_COEFFICIENT = 2.51;
            VOLUME_POWER = -0.74;
            
            cc = label2cc( segments );
            radius = zeros( cc.NumObjects, 1 );
            magnitude = zeros( cc.NumObjects, 1 );
            for i = 1 : cc.NumObjects
                gdt = obj.geodesic_distance_transform( segments == i, hotspots == i );
                L = max( gdt );
                W = median( gdt );
                T = max( edt( cc.PixelIdxList{ i } ) );
                sf = ( L + W ) ./ T;
                v_s = numel( cc.PixelIdxList{ i } );
                v_f = VOLUME_COEFFICIENT .* v_s .* ( sf .^ VOLUME_POWER );
                radius( i ) = ( v_f / ( 2.* obj.HEIGHT_DIAMETER_RATIO .* pi ) ) .^ ( 1 / 3 );
                magnitude( i ) = T;
            end
        end
    end
    
    methods ( Access = private, Static )
        function height_offset = compute_height_offset( segments, edt )
            cc = label2cc( segments );
            height_offset = zeros( cc.NumObjects, 1 );
            for i = 1 : cc.NumObjects
                height_offset( i ) = max( edt( cc.PixelIdxList{ i } ) );
            end
        end
        
        function values = geodesic_distance_transform( bw, idx )
            p = bwperim( bw );
            g = double( bwdistgeodesic( bw, idx, 'quasi-euclidean' ) );
            g( isnan( g ) ) = inf;
            g( ~p ) = inf;
            values = g( g < inf );
        end
        
        function fv = generate_fv( position, radius, height )
            SEGMENTS = 60;
            fv = capped_cylinder( radius, height, SEGMENTS, 'triangles' );
            fv.vertices = fv.vertices + position;
        end
    end
    
    properties ( Access = private, Constant )
        HEIGHT_DIAMETER_RATIO(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1.5
    end
    
end

