function projected = project( interior )

assert( ndims( interior ) == 3 );
assert( islogical( interior ) );

projected = any( interior, 3 );

end

