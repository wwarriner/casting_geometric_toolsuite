function fdm_mesh = generate_test_mesh( mold_id, melt_id, shape, melt_ratio )

if nargin < 4
    %center = floor( ( shape - 1 ) / 2 ) + 1;
    %quarter = floor( ( center - 1 ) / 2 );
    melt_ratio = 0.5;
end

melt_shape = melt_ratio .* shape;
melt_start = floor( ( shape - melt_shape ) ./ 2 );
melt_end = shape - melt_start + 1;

fdm_mesh = mold_id * ones( shape );
melt_ranges = arrayfun( ...
    @(s,e) s : e, ...
    melt_start, ...
    melt_end, ...
    'uniformoutput', false ...
    );
fdm_mesh( melt_ranges{ 1 }, melt_ranges{ 2 }, melt_ranges{ 3 } ) = melt_id;

end

