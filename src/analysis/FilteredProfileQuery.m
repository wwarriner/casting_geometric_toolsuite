classdef FilteredProfileQuery < handle
    % Filters the input profile by the input amount using the imhmax
    % morphological image reconstruction algorithm. Filtering occurs on both the
    % positive and negative values independently using the same input amount.
    
    methods ( Access = public )
        
        % - @profile is an ND double array similar to a signed distance field
        % - @amount is a positive double scalar indicating the amount to by
        % which to reduce local peak regions by, in the same units as values in
        % @profile
        function obj = FilteredProfileQuery( profile, amount )
            if nargin == 0
                return;
            end
            
            assert( isa( profile, 'double' ) );
            assert( isreal( profile ) );
            assert( all( isfinite( profile ), 'all' ) );
            
            assert( isscalar( amount ) );
            assert( isa( amount, 'double' ) );
            assert( isreal( amount ) );
            assert( isfinite( amount ) );
            assert( 0.0 < amount );
            
            mask = profile >= 0;
            obj.values = ...
                filter_masked( profile, mask, amount ) ...
                - filter_masked( -profile, ~mask, amount );
        end
        
        % - output values is ND array of signed distance field
        % - mask_optional is a logical array of size get_size() where false
        % elements are set to 0 in output values
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
        values(:,:,:) double {mustBeReal,mustBeFinite} = []
    end
    
end
