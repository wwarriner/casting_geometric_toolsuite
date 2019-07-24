classdef PartingLine < handle
    
    properties ( SetAccess = private )
        flatness(:,1) double
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint64
        label_array(:,:,:) uint64
        binary_array(:,:,:) logical
        draw(1,1) double
    end
    
    methods
        function obj = PartingLine( projected_perimeter, bounds, height )
            if nargin == 0
                return;
            end
            
            assert( isa( projected_perimeter, 'ProjectedPerimeter' ) );
            
            assert( ndims( bounds ) == 3 );
            assert( size( bounds, 3 ) == 2 );
            assert( isa( bounds, 'uint64' ) );
            
            assert( isscalar( height ) );
            assert( isa( height, 'uint64' ) );
            
            line = zeros( [ size( projected_perimeter.label_array ) height ] );
            flatness = zeros( projected_perimeter.count, 1 );
            for i = 1 : projected_perimeter.count
                proj_segment = projected_perimeter.label_array == i;
                [ path, flatness( i ) ] = obj.optimize_path( ...
                    proj_segment, ...
                    bounds ...
                    );
                segment = obj.unproject_path( path, height );
                line( segment ) = i;
                % TODO add verticals when unprojecting somehow
            end
            obj.cc = label2cc( line );
            obj.flatness = flatness;
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
        
        function value = get.draw( obj )
            bounds = compute_bounds( obj.binary_array );
            value = double( max( bounds, 'all' ) - min( bounds, 'all' ) + 1 );
        end
    end
    
    properties ( Access = private )
        cc(1,1) struct
    end
    
    methods ( Access = private )
        function [ path, flatness ] = optimize_path( obj, segment, bounds )
            loop = PerimeterLoop( segment );
            lower = bounds( :, :, 1 );
            upper = bounds( :, :, 2 );
            rbo = RubberBandOptimizer( ...
                double( lower( loop.indices ) ), ...
                double( upper( loop.indices ) ), ...
                loop.distances ...
                );
            path = zeros( size( segment ) );
            path( loop.indices ) = round( rbo.path );
            flatness = obj.compute_flatness( rbo.path, loop.distances );
        end
    end
    
    methods ( Access = private, Static )
        function segment = unproject_path( path, height )
            segment = unproject( ...
                uint64( cat( 3, path, path ) ), ...
                height ...
                );
        end
        
        function f = compute_flatness( path, distances )
            % 1D version of Flatness criterion
            % from Ravi B and Srinivasa M N, Computer-Aided Design 22(1), pp 11-18
            h = diff( [ path; path( 1 ) ] );
            d = sqrt( h .^ 2 + distances .^ 2 );
            f = sum( d ) ./ sum( distances );
        end
    end
    
end

