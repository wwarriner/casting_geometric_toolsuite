function inds = find_interface( lhs_bw, rhs_bw )
% @inds are the indices of elements in the perimeter of @lhs_bw that
% intersect @rhs_bw.
% Both @lhs_bw and @rhs_bw must be logical arrays of the same size.
assert( islogical( lhs_bw ) );

assert( islogical( rhs_bw ) );
assert( all( size( rhs_bw ) == size( lhs_bw ) ) );

lhs_bw = bwperim( lhs_bw );
lhs_bw = lhs_bw & rhs_bw;
inds = find( lhs_bw );

end

