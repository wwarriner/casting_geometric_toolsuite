classdef Segments < handle
    % @Segments encapsulates behavior and data of watershed segments. These are
    % intended to mirror isolated sections in casting geometries.
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint64
        label_array(:,:,:) double
    end
    
    methods
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
            
            segments = watershed_masked( -profile, mask );
            cc = bwconncomp( segments );
            cc.NumObjects = uint64( cc.NumObjects );
            obj.cc = cc;
        end
        
        function value = get.count( obj )
            value = obj.cc.NumObjects;
        end
        
        function value = get.label_array( obj )
            value = labelmatrix( obj.cc );
        end
    end
    
    properties ( Access = private )
        cc(1,1) struct
    end
    
end

