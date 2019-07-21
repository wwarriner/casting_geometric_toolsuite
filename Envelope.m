classdef (Sealed) Envelope < handle & matlab.mixin.Copyable
    
    properties ( SetAccess = private )
        dimension_count(1,1) uint64 {mustBePositive} = 1
        min_point(1,:) double {mustBeReal,mustBeFinite} = []
        max_point(1,:) double {mustBeReal,mustBeFinite} = []
        lengths(1,:) double {mustBeReal,mustBeFinite,mustBeNonnegative} = []
        volume(1,1) double {mustBeReal,mustBeFinite,mustBeNonnegative} = 0.0
    end
    
    methods ( Access = public )
        
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
            u = geometry.Envelope( new_min, new_max );
        end
        
    end
    
    
    methods ( Access = private )
        
        function construct_from_fv( obj, fv )
            assert( isstruct( fv ) || isobject( fv ) );
            if isstruct( fv )
                assert( isfield( fv, 'vertices' ) );
            elseif isobject( fv )
                assert( isprop( fv, 'vertices' ) );
            end
            
            obj.dimension_count = size( fv.vertices, 2 );
            obj.min_point = min( fv.vertices, [], 1 );
            obj.max_point = max( fv.vertices, [], 1 );
            obj.recompute();
        end
        
        
        function construct_from_points( obj, varargin )
            assert( nargin == 3 )
            
            min = varargin{ 1 };
            max = varargin{ 2 };
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
            obj.volume = prod( obj.lengths );
        end
        
    end
    
end

