classdef (Sealed) Envelope < handle & matlab.mixin.Copyable
    
    properties ( GetAccess = public, SetAccess = private )
        
        min_point;
        max_point;
        lengths;
        volume;
        
    end
    
    methods ( Access = public )
        
        % any one object like an fv struct
        % rows of fv.vertices must be points, columns dimensions/axes
        % -OR-
        % min_point, max_point as two vectors of length 3
        function obj = Envelope( varargin )
            
            if nargin == 0 || 2 < nargin
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
            
            obj.min_point = min( fv.vertices, [], 1 );
            obj.max_point = max( fv.vertices, [], 1 );
            
            obj.recompute();
            
        end
        
        
        function construct_from_points( obj, varargin )
            
            assert( nargin == 3 )
            
            min = varargin{ 1 };
            max = varargin{ 2 };
            
            assert( isnumeric( min ) && isnumeric( max ) );
            assert( isvector( min ) && isvector( max ) );
            assert( numel( min ) == 3 && numel( max ) == 3 );
            assert( all( isfinite( min ) ) && all( isfinite( max ) ) );
            
            obj.min_point = min( : ).';
            obj.max_point = max( : ).';
            
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

