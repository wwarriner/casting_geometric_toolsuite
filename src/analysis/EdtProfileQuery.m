classdef EdtProfileQuery < handle
    % @EdtProfileQuery computes the signed distance field of an input logical
    % feature array, using the input mask to determine regions of negative
    % value. Elements with true in the feature array have zero value in the
    % distance field, and non-zero values elsewhere. The intent is to supply a
    % method for rapidly estimating a solidification profile in casting
    % geometries in a manner like Heuvers' circles.
    
    methods ( Access = public )
        % - @features is an ND logical array with true designating the boundary
        % (zero distance) and false designating the region filled by distances
        % greater than zero.
        % - @mask is an ND logical array the same size as @features which 
        % reflects regions to be marked with negative distance. Default gives 
        % positive distance everywhere.
        function obj = EdtProfileQuery( features, mask )
            if nargin == 0
                return;
            end
            
            if nargin < 2
                mask = false( size( features ) );
            end
            
            assert( islogical( features ) );
            
            assert( islogical( mask ) );
            
            v = bwdist( features );
            v( mask ) = -v( mask );
            obj.values = v;
        end
        
        % @get returns the distance field masked in by @mask_optional.
        % - @values is an ND array of signed distance field.
        % - @scale is is a factor multiplied by the returned field.
        % - @mask_optional is a logical array of size @get_size() where false 
        % elements are set to 0 in @values. Default is all true.
        function values = get( obj, scale, mask_optional )
            if nargin < 2
                scale = 1;
            end
            if nargin < 3
                mask_optional = true( size( obj.values ) );
            end
            assert( islogical( mask_optional ) );
            assert( all( size( obj.values ) == size( mask_optional ) ) );
            
            values = scale .* obj.values;
            values( ~mask_optional ) = 0;
        end
    end
    
    properties ( Access = private )
        values(:,:,:) double {mustBeReal,mustBeFinite} = []
    end
    
end

