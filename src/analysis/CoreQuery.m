classdef CoreQuery < handle
    % @CoreQuery is intended to identify regions in a voxel
    % representation of a solid body which roughly approximate the required
    % cores to cast that body. The intent is to take the undercuts and
    % connect them together using an algorithm that expands and merges
    % them.
    
    properties ( SetAccess = private )
        count(1,1) uint64
        label_array(:,:,:) uint64
    end
    
    methods
        % Inputs:
        % - @undercuts is a logical array representing the undercuts of
        % some logical image (as from @UndercutQuery).
        % - @exterior is a logical array representing the exterior of the
        % same logical image referred to previously. For a casting this
        % would be everything outside the cavity.
        % - @threshold is a real, finite, positive scalar double which
        % determines how far to expand the undercuts when merging.
        function obj = CoreQuery( undercuts, exterior, threshold )
            if nargin == 0
                return;
            end
            
            assert( ndims( exterior ) == 3 );
            assert( islogical( exterior ) );
            
            assert( ndims( undercuts ) == 3 );
            assert( islogical( undercuts ) );
            assert( all( size( exterior ) == size( undercuts ) ) );
            
            assert( isscalar( threshold ) );
            assert( isa( threshold, 'double' ) );
            assert( isreal( threshold ) );
            assert( isfinite( threshold ) );
            
            expanded = expand_masked( undercuts, exterior, threshold );
            obj.cc = bwconncomp( expanded );
        end
        
        function value = get.count( obj )
            value = uint64( obj.cc.NumObjects );
        end
        
        function value = get.label_array( obj )
            value = uint64( labelmatrix( obj.cc ) );
        end
    end
    
    properties ( Access = private )
        cc(1,1) struct
    end
    
end

