classdef PerimeterLoop < handle
    
    properties
        perimeter(:,:) logical
        distances(:,1) double {mustBeReal,mustBeFinite,mustBePositive}
        indices(:,1) uint64 {mustBePositive}
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
            indices = uint64( indices( 1 : end - 1 ) );
        end
        
        function [ distance, index ] = get_next( obj, index, perimeter )
            neighbors = index + generate_neighbor_offsets( perimeter );
            valid_neighbors = perimeter( neighbors ) == true;
            next = find( valid_neighbors( obj.preferred_neighbors ), 1 );
            if isempty( next )
                index = [];
                distance = [];
            else
                preference = obj.preferred_neighbors( next );
                index = neighbors( preference );
                distance = obj.neighbor_distances( preference );
            end
        end
    end
    
    methods ( Access = private, Static )
        function perimeter = clean_perimeter( image )
            a = imfill( image, 'holes' );
            b = bwperim( a );
            c = bwmorph( b, 'thin', inf );
            d = bwmorph( c, 'spur', inf );
            perimeter = bwmorph( d, 'thin', inf );
            
            assert( any( perimeter, 'all' ) );
        end
        
        
    end
    
end

