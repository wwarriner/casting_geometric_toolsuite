classdef Segments < handle
    % Segments encapsulated behavior and data of watershed segments.
    
    properties ( GetAccess = public, SetAccess = private, Dependent )
        count
        label_matrix
    end
    
    
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
            
            obj.values = obj.label( profile, mask );
        end
        
    end
    
    
    methods % getters
        
        function value = get.count( obj )
            value = numel( unique( obj.values ) ) - 1;
        end
        
        function value = get.label_matrix( obj )
            value = obj.values;
        end
        
    end
    
    
    properties ( Access = private )
        values(:,:,:) double {mustBeReal,mustBeFinite,mustBeNonnegative} = []
    end
    
    
    methods ( Access = private, Static )
        
        function segments = label( profile, mask )
            profile( ~mask ) = -inf;
            segments = double( watershed( -profile ) );
            segments( ~mask ) = 0;
        end
        
    end
    
end

