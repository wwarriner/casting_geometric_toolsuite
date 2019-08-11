classdef PerimeterLoop < handle
    
    properties
        perimeter(:,:) logical
        distances(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        indices(:,1) uint32 {mustBePositive}
    end
    
    methods
        function obj = PerimeterLoop( image )
            cc = bwconncomp( image );
            assert( cc.NumObjects == 1 );
            
            obj.perimeter = obj.clean_perimeter( image );
            [ obj.distances, obj.indices ] = obj.get_loop_distances( obj.perimeter );
        end
    end
    
    properties ( Access = private )
        preferred_neighbors(:,1) = [ 7 8 5 3 2 1 4 6 ];
        neighbor_distances(:,1) = [ sqrt( 2 ) 1 sqrt( 2 ) 1 1 sqrt( 2 ) 1 sqrt( 2 ) ];
    end
    
    methods ( Access = private )
        function [ distances, indices ] = get_loop_distances( obj, perimeter )
            element_count = sum( perimeter, 'all' );
            indices = zeros( 1, element_count + 1 );
            distances = zeros( 1, element_count );
            
            itr = 1;
            indices( itr ) = find( perimeter, 1 );
            itr = itr + 1;
            
            while true
                previous = indices( itr - 1 );
                [ distance, next ] = obj.get_next( previous, perimeter );
                if isempty( next )
                    break;
                end
                indices( itr ) = next;
                distances( itr - 1 ) = distance;
                perimeter( next ) = 0;
                itr = itr + 1;
            end
            assert( indices( 1 ) == indices( end ) );
            indices = uint32( indices( 1 : end - 1 ) );
        end
        
        function [ distance, index ] = get_next( obj, index, perimeter )
            n_subs = generate_neighbor_subs( perimeter );
            n_subs = n_subs( obj.preferred_neighbors, : );
            c_subs = ind2sub_vec( size( perimeter ), index );
            neighbors = n_subs + c_subs;
            remove = neighbors( :, 1 ) < 1 | size( perimeter, 1 ) < neighbors( :, 1 ) ...
                | neighbors( :, 2 ) < 1 | size( perimeter, 2 ) < neighbors( :, 2 );
            neighbors( remove, : ) = [];
            inds = sub2ind_vec( size( perimeter ), neighbors );
            valid_neighbors = perimeter( inds ) == true;
            next = find( valid_neighbors, 1 );
            if isempty( next )
                index = [];
                distance = [];
            else
                index = inds( next );
                nd = obj.neighbor_distances;
                nd( remove ) = [];
                distance = nd( next );
            end
        end
    end
    
    methods ( Access = private, Static )
        function perimeter = clean_perimeter( image )
            a = imfill( image, 'holes' );
            b = bwperim( a );
            c = bwmorph( b, 'thin', inf );
            % padding required for despurring at image border
            d = bwmorph( padarray( c, [ 1 1 ], false ), 'spur', inf );
            d = d( 2 : end - 1, 2 : end - 1 );
            perimeter = bwmorph( d, 'thin', inf );
            
            assert( any( perimeter, 'all' ) );
        end
        
        
    end
    
end

