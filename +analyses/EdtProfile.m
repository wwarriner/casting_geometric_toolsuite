classdef EdtProfile < handle
    % Computes the signed distance field of input logical feature array, using
    % the input mask to determine regions of negative value. Elements with true
    % in the feature array have zero value in the distance field, and non-zero
    % values elsewhere.
    
    methods ( Access = public )
        
        % - @features is an ND logical array with true designating the boundary
        % (zero distance) and false designating the region filled by distances
        % greater than zero.
        % - @mask is an ND logical array the same size as @features which 
        % reflects regions to be marked with negative distance. Default gives 
        % positive distance everywhere.
        function obj = EdtProfile( features, mask )
            if nargin == 0
                return;
            end
            
            assert( islogical( features ) );
            
            if nargin < 2
                mask = false( size( features ) );
            end
            
            assert( islogical( mask ) );
            
            v = bwdist( features );
            v( mask ) = -v( mask );
            obj.values = v;
        end
        
        
        % @scale scales the values in the distance field by @factor.
        % - @factor is a real, positive, finite, scalar double.
        function scale( obj, factor )
            assert( isscalar( factor ) );
            assert( isa( factor, 'double' ) );
            assert( isreal( factor ) );
            assert( isfinite( factor ) );
            assert( 0.0 < factor );
            
            obj.values = obj.values .* factor;
        end
        
        
        % @get returns the distance field masked in by @mask_optional.
        % - @values is an ND array of signed distance field.
        % - @mask_optional is a logical array of size @get_size() where false 
        % elements are set to 0 in @values. Default is all true.
        function values = get( obj, mask_optional )
            if nargin < 2
                mask_optional = true( size( obj.values ) );
            end
            assert( islogical( mask_optional ) );
            assert( all( size( obj.values ) == size( mask_optional ) ) );
            
            values = obj.values;
            values( ~mask_optional ) = 0;
        end
        
    end
    
    
    properties ( Access = private )
        values double {mustBeReal,mustBeFinite} = [];
    end
    
end

