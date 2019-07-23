classdef PartingLine < handle
    
    properties ( SetAccess = private, Dependent )
        count
        label_matrix
        line
    end
    
    methods
        function obj = PartingLine( ...
                interior, ...
                projected_label_matrix, ...
                limits ...
                )
            if nargin == 0
                return;
            end
            
            assert( ndims( interior ) == 3 );
            assert( islogical( interior ) );
            
            assert( ismatrix( projected_label_matrix ) );
            assert( isa( projected_label_matrix, 'uint64' ) );
            
            assert( ndims( limits ) == 3 );
            assert( size( limits, 3 ) == 2 );
            assert( isa( limits, 'double' ) );
            assert( isreal( limits ) );
            assert( all( isfinite( limits ), 'all' ) );
            assert( all( limits >= 0, 'all' ) );
            
            obj.values = zeros( size( interior ) );
            for i = 1 : numel( unique( projected_label_matrix ) ) - 1
                PP = Perimeter( projected_label_matrix == i );
                
                min_slice = limits( :, :, 1 );
                max_slice = limits( :, :, 2 );
                pl = analyses.RubberBandOptimizer( ...
                    min_slice( PP.indices ), ...
                    max_slice( PP.indices ), ...
                    PP.distances ...
                    );
                path_height = nan( size( projected_label_matrix ) );
                path_height( PP.indices ) = round( pl.path );
                
                unprojected_parting_line = unproject( ...
                    interior, ...
                    uint64( cat( 3, path_height, path_height ) ) ...
                    );
                % TODO add verticals when unprojecting somehow
                obj.values( unprojected_parting_line > 0 ) = i;
                %obj.flatness = pl.flatness;
            end
        end
        
        function value = get.count( obj )
            value = uint64( numel( unique( obj.values ) ) - 1 );
        end
        
        function value = get.label_matrix( obj )
            value = obj.values;
        end
        
        function value = get.line( obj )
            value = obj.values > 0;
        end
    end
    
    properties ( Access = private )
        values(:,:,:) double {mustBeReal,mustBeFinite,mustBeNonnegative} = []
    end
    
end

