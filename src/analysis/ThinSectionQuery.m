classdef ThinSections < handle
    % @ThicknessThreshold is intended to identify regions in a voxel
    % representation of a solid body which are above and below some
    % threshold local wall thickness. The intent is to identify thin wall
    % regions of castings based on some thin wall threshold.
    
    properties ( SetAccess = private )
        count(1,1) uint32
        label_array(:,:,:) uint32
    end
    
    methods
        % Inputs:
        % - @edt is a real, positive double array representing the edt
        % profile of some logical image (as from bwdist) and should have
        % values everywhere in the mask. Values outside the mask are
        % ignored. Values must be in voxel units.
        % - @mask is a logical array where only true values are considered
        % for computation.
        % - @threshold is a real, finite, positive scalar double
        % representing the thickness threshold in voxel units.
        % - @sweep_coefficient (optional) is a real, finite, positive
        % scalar double which determines how aggressively to sweep. Lower
        % values tend to undersegment, and higher values oversegment.
        function obj = ThinSections( edt, mask, threshold, sweep_coefficient )
            if nargin == 0
                return;
            end
            
            if nargin < 5
                sweep_coefficient = 2; % seems to work well
            end
            
            assert( ndims( edt ) == 3 );
            assert( isa( edt, 'double' ) );
            assert( isreal( edt ) );
            
            assert( ndims( mask ) == 3 );
            assert( islogical( mask ) );
            assert( all( size( edt ) == size( mask ) ) );
            
            assert( isscalar( threshold ) );
            assert( isa( threshold, 'double' ) );
            assert( isreal( threshold ) );
            assert( isfinite( threshold ) );
            
            assert( isscalar( sweep_coefficient ) );
            assert( isa( sweep_coefficient, 'double' ) );
            assert( isreal( sweep_coefficient ) );
            assert( isfinite( sweep_coefficient ) );
            
            sweep_distance = max( threshold, 1 );
            sweep_distance = sweep_coefficient .* sweep_distance;
            sweep = distance_sweep( mask, edt > threshold, sweep_distance );
            sweep = distance_sweep( mask, ~sweep & mask, sweep_distance );
            obj.cc = bwconncomp( sweep & mask );
        end
        
        function count = get.count( obj )
            count = uint32( obj.cc.NumObjects );
        end
        
        function value = get.label_array( obj )
            value = uint32( labelmatrix( obj.cc ) );
        end
    end
    
    properties ( Access = private )
        cc(1,1) struct
    end
    
end

