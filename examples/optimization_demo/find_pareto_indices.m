function pareto_indices = find_pareto_indices( objectives )
%% SCALED SUMS FOR SORTING
% This maximizes efficiency if the top scaled sum is dominant over many
% Reasonable assumption in many cases
scaled_sums = objectives;
objective_count = size( objectives, 2 );
for i = 1 : objective_count
    scaled_sums( :, i ) = rescale( scaled_sums( :, i ) );
end
scaled_sums = sum( scaled_sums, 2 );

%% INDICES TO STORE LATER
row_count = size( objectives, 1 );
indices = ( 1 : row_count ).';

%% FIND PARETO INDICES
pareto_indices = nan( row_count, 1 );
index_count = 1;
while ~isempty( objectives )
    %% SORT BY SCALED SUMS
    [ scaled_sums, sort_indices ] = sort( scaled_sums, 1, 'ascend' );
    objectives = objectives( sort_indices, : );
    indices = indices( sort_indices );
    
    %% DETERMINE IF CURRENT IS PARETO DOMINANT
    % and which others it is dominant over
    top = objectives( 1, : );
    less = ( top < objectives( 2 : end, : ) );
    less_equal = ( top <= objectives( 2 : end, : ) );
    dominated = all( less_equal, 2 ) & any( less, 2 );
    pareto_dominant = sum( dominated ) > 0;
    
    %% REMOVE NON-DOMINANT ENTRIES
    % and store index if current is dominant
    if pareto_dominant
        objectives( dominated, : ) = [];
        scaled_sums( dominated, : ) = [];
        indices( dominated, : ) = [];
        pareto_indices( index_count ) = indices( 1 );
        index_count = index_count + 1;
    else
        % not pareto dominant
    end
    objectives( 1, : ) = [];
    scaled_sums( 1, : ) = [];
    indices( 1, : ) = [];
    
end
pareto_indices( any( isnan( pareto_indices ), 2 ) ) = [];

end