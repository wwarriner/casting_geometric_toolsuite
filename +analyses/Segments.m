classdef Segments < handle
    % Segments encapsulated behavior and data of watershed segments.
    
    methods ( Access = public )
        
        % - @profile is an ND double array representing some watershed-sensible
        % profile.
        % - @mask is a logical array of the same size as @profile of the region
        % to apply the watershed to. All elements not in the mask are assigned
        % the watershed segment 0, i.e. the boundary value of watershed().
        function obj = Segments( profile, mask )
            if nargin == 0
                return;
            end
            
            assert( isa( profile, 'double' ) );
            assert( isreal( profile ) );
            assert( all( isfinite( profile ), 'all' ) );
            
            assert( islogical( mask ) );
            assert( all( size( mask ) == size( profile ) ) );
            
            obj.values = obj.compute_segments( profile, mask );
        end
        
        % @get_count() returns the number of segments.
        % - @count is a scalar double representing the number of segments.
        function count = get_count( obj )
            count = numel( unique( obj.values ) ) - 1; % discount 0 value
        end
        
        % @get() returns a connected component (CC) struct representing the
        % segments labeled by @indices.
        % - @segments is a connected component struct.
        % - @indices is a vector of values falling in the range
        % [1,@get_count()].
        function segments = get( obj, indices )
            if nargin < 2
                indices = 1 : obj.get_count();
            end
            
            assert( isnumeric( indices ) );
            assert( isvector( indices ) );
            assert( all( ismember( indices, 1 : obj.get_count() ) ) );
            
            segments = bwconncomp( obj.get_as_label_matrix() );
        end
        
        % @get_as_label_matrix() returns a label matrix representing the
        % segments labled by @indices.
        % - @segments is a label matrix of the same size as the inputs to the
        % constructor.
        % - @indices is a vector of values falling in the range
        % [1,@get_count()].
        function segments = get_as_label_matrix( obj, indices )
            if nargin < 2
                indices = 1 : obj.get_count();
            end
            
            assert( isnumeric( indices ) );
            assert( isvector( indices ) );
            assert( all( ismember( indices, 1 : obj.get_count() ) ) );
            
            segments = obj.values;
            segments( ~ismember( segments, indices ) ) = 0;
        end
        
    end
    
    
    properties ( Access = private )
        values double {mustBeReal,mustBeFinite,mustBeNonnegative} = [];
    end
    
    
    methods ( Access = private, Static )
        
        function segments = compute_segments( profile, mask )
            profile( ~mask ) = -inf;
            segments = double( watershed( -profile ) );
            segments( ~mask ) = 0;
        end
        
    end
    
end

