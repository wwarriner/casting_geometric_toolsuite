classdef PartingPerimeter < handle
    
    properties ( GetAccess = public, SetAccess = private, Dependent )
        count
        label_matrix
        perimeter
    end
    

    properties ( GetAccess = public, SetAccess = private )
        limits(:,:,2) double {mustBeReal,mustBeFinite,mustBeNonnegative} = [];
    end
    
    
    methods ( Access = public )
        
        function obj = PartingPerimeter( interior, projected_perimeter )
            if nargin == 0
                return;
            end
            
            assert( ndims( interior ) == 3 );
            assert( islogical( interior ) );
            
            assert( ismatrix( projected_perimeter ) );
            assert( islogical( projected_perimeter ) );
            
            obj.limits = obj.determine_limits( interior, projected_perimeter );
            perimeter = obj.unproject_perimeter( interior, projected_perimeter, obj.limits );
            obj.values = obj.label( perimeter );
            
        end
        
    end
    
    
    methods % getters
        
        function value = get.count( obj )
            value = uint64( numel( unique( obj.values ) ) - 1 );
        end
        
        function value = get.label_matrix( obj )
            value = obj.values;
        end
        
        function value = get.perimeter( obj )
            value = obj.values > 0;
        end
        
    end
    
    
    properties ( Access = private )
        values(:,:,:) double {mustBeReal,mustBeFinite,mustBeNonnegative} = []
    end
    
    
    methods ( Access = private, Static )
        
        function limits = determine_limits( interior, projected_perimeter )
            sz = size( interior );
            [ ~, ~, Z ] = meshgrid( 1 : sz( 2 ), 1 : sz( 1 ), 1 : sz( 3 ) );
            sweep = repmat( projected_perimeter, [ 1 1 sz( 3 ) ] );
            Z( ~( sweep & interior ) ) = nan;
            lower = min( Z, [], 3 );
            lower( ~projected_perimeter ) = inf;
            lower = imerode( lower, conndef( 2, 'maximal' ) );
            lower( ~projected_perimeter ) = 0;
            upper = max( Z, [], 3 );
            upper( ~projected_perimeter ) = -inf;
            upper = imdilate( upper, conndef( 2, 'maximal' ) );
            upper( ~projected_perimeter ) = 0;
            limits = cat( 3, lower, upper );
        end
        
        function perimeter = unproject_perimeter( interior, projected_perimeter, limits )
            sz = size( interior );
            perimeter = zeros( sz );
            for i = 1 : sz( 1 )
                for j = 1 : sz( 2 )
                    if projected_perimeter( i, j ) <= 0
                        continue;
                    end
                    perimeter( i, j, limits( i, j, 1 ) : limits( i, j, 2 ) ) = true;
                end
            end
        end
        
        function labels = label( perimeter )
            labels = labelmatrix( bwconncomp( ...
                perimeter, ...
                conndef( 3, 'maximal' ) ...
                ) );
        end
        
    end
    
end

