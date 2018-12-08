function adjusted_image = remove_small_connected_regions( ...
    binary_image, ...
    connectivity_matrix ...
    )
%% INPUTS
if nargin < 2
    connectivity_matrix = conndef( ndims( binary_image ), 'minimal' );
end

%% IDENTIFY CONNECTED REGIONS
connected_regions = bwconncomp( binary_image, connectivity_matrix );
segments = double( labelmatrix( connected_regions ) );
segment_count = connected_regions.NumObjects;

%% COMPUTE RATIOS
segment_element_counts = arrayfun( @(y)sum( segments( : ) == y ), 1 : segment_count );
segment_element_ratios = segment_element_counts ./ prod( size( binary_image ) );

%% THRESHOLD REGIONS BY RATIO
indices_to_remove = ...
    isoutlier( 1 ./ segment_element_counts, 'quartiles' ) ...
    | segment_element_ratios < 1e-4;
adjusted_image = segments;
for i = 1 : segment_count
    if indices_to_remove( i )
        adjusted_image( adjusted_image == i ) = 0;
    end
end
adjusted_image = double( adjusted_image > 0 );

end

