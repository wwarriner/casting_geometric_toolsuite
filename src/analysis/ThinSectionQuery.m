classdef ThinSectionQuery < handle
    % @ThinSectionQuery is intended to identify regions in a voxel
    % representation of a solid body which are below some threshold local wall
    % thickness. The intent is to identify thin wall regions of castings based 
    % on some thin wall threshold.
    
    properties ( SetAccess = private, Dependent )
        count(1,1) double
        label_array(:,:,:) uint32
        regional_maxima(:,:,:) uint32
    end
    
    methods
        % Inputs:
        % - @edt is a real, positive double array representing the edt profile 
        % of some logical image (as from bwdist) and should have values 
        % everywhere in @mask. Values outside the mask are ignored. Values must 
        % be in voxel units.
        % - @mask is a logical array where only true values are considered
        % for computation.
        % - @threshold is a real, finite, positive scalar double representing
        % the thickness threshold in voxel units.
        % - @sweep_coefficient (optional) is a real, finite, positive
        % scalar double which determines how aggressively to sweep. Lower
        % values tend to undersegment, and higher values oversegment.
        function obj = ThinSectionQuery( edt, mask, threshold, sweep_coefficient )
            if nargin == 0
                return;
            end
            
            if nargin < 4
                sweep_coefficient = 2; % seems to work well
            end
            
            assert( isa( edt, 'double' ) );
            assert( ndims( edt ) == 3 );
            assert( isreal( edt ) );
            assert( all( isfinite( edt ), 'all' ) );
            
            assert( islogical( mask ) );
            assert( ndims( mask ) == 3 );
            assert( all( size( edt ) == size( mask ) ) );
            
            assert( isscalar( threshold ) );
            assert( isa( threshold, 'double' ) );
            assert( isreal( threshold ) );
            assert( isfinite( threshold ) );
            
            assert( isscalar( sweep_coefficient ) );
            assert( isa( sweep_coefficient, 'double' ) );
            assert( isreal( sweep_coefficient ) );
            assert( isfinite( sweep_coefficient ) );
            
            sweep_distance = sweep_coefficient .* threshold;
            sweep_distance = max( sweep_distance, 1 );
            sweep = distance_sweep( mask, edt > threshold, sweep_distance );
            sweep = distance_sweep( mask, ~sweep & mask, sweep_distance );
            cc = bwconncomp( sweep & mask );
            
            rm = edt;
            rm( ~( sweep & mask ) ) = 0;
            rm = imregionalmax( rm );
            % TODO better skeletonizing algorithm, maybe onion peel?
            cc_rm = bwconncomp( rm );
            
            obj.cc = cc;
            obj.cc_rm = cc_rm;
        end
        
        function count = get.count( obj )
            count = obj.cc.NumObjects;
        end
        
        function value = get.label_array( obj )
            value = uint32( labelmatrix( obj.cc ) );
        end
        
        function value = get.regional_maxima( obj )
            value = uint32( labelmatrix( obj.cc_rm ) );
            value( value > 0 ) = obj.label_array( value > 0 );
        end
    end
    
    properties ( Access = private )
        cc(1,1) struct
        cc_rm(1,1) struct
    end
    
end

