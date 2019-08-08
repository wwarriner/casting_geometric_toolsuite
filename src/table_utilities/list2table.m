function t = list2table( names, values )

assert( iscell( names ) );
assert( isvector( names ) );

assert( iscell( values ) );
assert( isvector( values ) );
assert( length( names ) == length( values ) );

t = table( values{ : }, 'variablenames', names );

end

