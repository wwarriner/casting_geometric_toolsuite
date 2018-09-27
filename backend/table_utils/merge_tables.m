function lhs = merge_tables( lhs, rhs, rhs_prefix )

lhs_empty = ~height( lhs ) || ~width( lhs );
rhs_empty = ~height( rhs ) || ~width( rhs );
if ~lhs_empty && ~rhs_empty
    assert( height( lhs ) == height( rhs ) );
end
rhs.Properties.VariableNames = cellfun( ...
    @(x) [ rhs_prefix '_' x ], ...
    rhs.Properties.VariableNames, ...
    'uniformoutput', 0 ...
    );
lhs = [ lhs rhs ];

end