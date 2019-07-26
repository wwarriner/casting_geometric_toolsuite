function fv = compute_convex_hull( fv )

fv = convhulln( fv );
removed = setdiff( 1 : size( fv.vertices, 1 ), unique( fv.faces ) );
fv.vertices( removed ) = [];

end

