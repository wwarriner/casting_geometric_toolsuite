classdef Envelope < handle & matlab.mixin.Copyable
    
    properties ( SetAccess = private )
        dimension_count(1,1) uint32 {mustBePositive} = 1
        min_point(1,:) double {mustBeReal,mustBeFinite} = []
        max_point(1,:) double {mustBeReal,mustBeFinite} = []
        lengths(1,:) double {mustBeReal,mustBeFinite,mustBeNonnegative} = []
        volume(1,1) double {mustBeReal,mustBeFinite,mustBeNonnegative} = 0.0
    end
    
    methods
        % any one object like an fv struct
        % rows of fv.vertices must be points, columns dimensions
        % -OR-
        % min_point, max_point as two vectors
        function obj = Envelope( varargin )
            if nargin == 0
                return;
            end
            if 2 < nargin
                assert( false )
            end
            
            first = varargin{ 1 };
            if isstruct( first ) || isobject( first )
                obj.construct_from_fv( first );
            elseif isvector( first )
                obj.construct_from_points( varargin{ : } );
            else
                assert( false );
            end
        end
        
        function u = union( obj, envelope )
            assert( obj.dimension_count == envelope.dimension_count );
            
            new_min = min( obj.min_point, envelope.min_point );
            new_max = max( obj.max_point, envelope.max_point );
            u = Envelope( new_min, new_max );
        end
        
        function clone = collapse_to( obj, dimensions, values )
            assert( isnumeric( dimensions ) );
            assert( isreal( dimensions ) );
            assert( all( isfinite( dimensions ) ) );
            assert( all( ismember( dimensions, 1 : obj.dimension_count ) ) );
            
            if nargin < 3
                values = mean( [ obj.min_point; obj.max_point ] );
                values = values( dimensions );
            end
            
            assert( isnumeric( values ) );
            assert( isreal( values ) );
            assert( all( isfinite( values ) ) );
            assert( numel( values ) == numel( dimensions ) );
            
            clone = obj.copy;
            for i = 1 : numel( dimensions )
                d = dimensions( i );
                clone.min_point( d ) = values( i );
                clone.max_point( d ) = values( i );
            end
            clone.recompute();
        end
    end
    
    methods ( Access = private )
        function construct_from_fv( obj, fv )
            assert( isstruct( fv ) );
            assert( isfield( fv, 'vertices' ) );
            
            obj.dimension_count = size( fv.vertices, 2 );
            obj.min_point = min( fv.vertices, [], 1 );
            obj.max_point = max( fv.vertices, [], 1 );
            obj.recompute();
        end
        
        function construct_from_points( obj, varargin )
            assert( nargin == 3 )
            
            min = varargin{ 1 };
            max = varargin{ 2 };
            assert( isvector( min ) );
            assert( isvector( max ) );
            assert( numel( min ) == numel( max ) );
            
            obj.dimension_count = numel( min );
            obj.min_point = min;
            obj.max_point = max;
            obj.recompute();
        end
        
        function recompute( obj )
            obj.min_point = min( obj.min_point, obj.max_point );
            obj.max_point = max( obj.min_point, obj.max_point );
            obj.lengths = obj.max_point - obj.min_point;
            p_lengths = obj.lengths;
            p_lengths( p_lengths == 0 ) = [];
            obj.volume = prod( p_lengths );
            obj.dimension_count = numel( p_lengths );
        end
    end
    
end

