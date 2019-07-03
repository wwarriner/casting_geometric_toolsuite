classdef Undercuts < handle
    % Undercuts identifies regions in any column lying between two points in the
    % interior, then finds the resulting connected components.
    
    methods ( Access = public )
        
        % - @interior is a logical array representing a rasterized solid body.
        function obj = Undercuts( interior )
            if nargin == 0
                return;
            end
            
            assert( islogical( interior ) );
            
            [ rotated_interior, inverse ] = rotate_to_dimension( 3, interior );
            sz = size( rotated_interior );
            uc = zeros( sz );
            for k = 1 : sz( 3 )
                for j = 1 : sz( 2 )
                    painting = false;
                    [ uc, painting ] = obj.paint_forward( rotated_interior, uc, j, k, painting );
                    uc = obj.unpaint_reverse( rotated_interior, uc, j, k, painting );
                end
            end
            uc = rotate_from_dimension( uc, inverse );
            uc = obj.remove_spurious_undercuts( uc );
            obj.values = labelmatrix( bwconncomp( uc ) );
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
        function undercuts = get( obj, indices )
            if nargin < 2
                indices = 1 : obj.get_count();
            end
            
            assert( isnumeric( indices ) );
            assert( isvector( indices ) );
            assert( all( ismember( indices, 1 : obj.get_count() ) ) );
            
            undercuts = bwconncomp( obj.get_as_label_matrix() );
        end
        
        % @get_as_label_matrix() returns a label matrix representing the
        % segments labled by @indices.
        % - @segments is a label matrix of the same size as the inputs to the
        % constructor.
        % - @indices is a vector of values falling in the range
        % [1,@get_count()].
        function undercuts = get_as_label_matrix( obj, indices )
            if nargin < 2
                indices = 1 : obj.get_count();
            end
            
            assert( isnumeric( indices ) );
            assert( isvector( indices ) );
            assert( all( ismember( indices, 1 : obj.get_count() ) ) );
            
            undercuts = obj.values;
            undercuts( ~ismember( undercuts, indices ) ) = 0;
        end
        
    end
    
    
    properties ( Access = private )
        values double {mustBeReal,mustBeFinite,mustBeNonnegative} = []
    end
    
    
    methods ( Access = private, Static )
        
        function [ uc, painting ] = paint_forward( interior, uc, j, k, painting )
            for i = 1 : size( interior, 1 )
                if ~painting && interior( i, j, k )
                    painting = true;
                end
                if painting == true && ~interior( i, j, k )
                    uc( i, j, k ) = 1;
                end
            end
        end
        
        function uc = unpaint_reverse( interior, uc, j, k, painting )
            if ~painting
                return;
            end
            for i = size( interior, 1 ) : -1 : 1
                if painting == true
                    if ~interior( i, j, k )
                        uc( i, j, k ) = 0;
                    else
                        break;
                    end
                end
            end
        end
        
        function uc = remove_spurious_undercuts( uc )
            uc = remove_small_connected_regions( uc );
        end
        
    end
    
end

