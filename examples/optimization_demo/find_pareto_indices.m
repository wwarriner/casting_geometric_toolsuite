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

%% ORIGINAL INDICES TO STORE AS PARETO INDICES
row_count = size( objectives, 1 );
original_indices = ( 1 : row_count ).';

%% ORIGINAL OBJECTIVES TO ENSURE PARETO DOMINANCE
full_objectives = objectives;

%% CANDIDATE OBJECTIVE
% dominated points are removed at each iteration
candidate_objectives = objectives;

%% FIND PARETO INDICES
pareto_indices = nan( row_count, 1 );
index_count = 1;
while ~isempty( candidate_objectives )
    %% SORT CANDIDATES BY SCALED SUMS
    [ scaled_sums, sort_indices ] = sort( scaled_sums, 1, 'ascend' );
    candidate_objectives = candidate_objectives( sort_indices, : );
    original_indices = original_indices( sort_indices );
    
    %% DETERMINE IF TOP IS PARETO DOMINANT
    % and which others it is dominant over
    top = candidate_objectives( 1, : );
    greater = ( top > full_objectives );
    greater_equal = ( top >= full_objectives );
    pareto_dominant = ~( all( greater_equal ) & any( greater ) );
    
    %% REMOVE NON-DOMINANT ENTRIES
    % and store index if current is dominant
    if pareto_dominant
        less = ( top < candidate_objectives );
        less_equal = ( top <= candidate_objectives );
        dominated = all( less_equal, 2 ) & any( less, 2 );
    
        candidate_objectives( dominated, : ) = [];
        scaled_sums( dominated, : ) = [];
        original_indices( dominated, : ) = [];
        pareto_indices( index_count ) = original_indices( 1 );
        index_count = index_count + 1;
    end
    
    %% REMOVE TOP FROM CANDIDATES
    candidate_objectives( 1, : ) = [];
    scaled_sums( 1, : ) = [];
    original_indices( 1, : ) = [];
    
end
pareto_indices( any( isnan( pareto_indices ), 2 ) ) = [];

end