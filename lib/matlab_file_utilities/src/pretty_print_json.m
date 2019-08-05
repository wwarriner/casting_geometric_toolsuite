function json_str = pretty_print_json( json_str )

befores = [ "," "{" "[" ];
reps = [ befores; arrayfun( @(x)strjoin( [ x newline ], "" ), befores ) ];
afters = [ "}" "]" ];
reps = [ reps [ afters; arrayfun( @(x)strjoin( [ newline x ], "" ), afters ) ] ];
for i = 1 : size( reps, 2 )
    json_str = strrep( json_str, reps( 1, i ), reps( 2, i ) );
end

json_str = strsplit( json_str, newline );
c = numel( json_str );
depth = 0;
tab = string( char( 9 ) );
for i = 2 : c - 1 % ignore first and last {} or []
    t = repmat( tab, [ 1 depth ] );
    s = json_str( i );
    json_str( i ) = strjoin( [ t s ], "" );
    if endsWith( s, [ "[" "{" ] )
        depth = depth + 1;
    elseif endsWith( s, [ "]" "}", "}," ] )
        depth = depth - 1;
    end
end
json_str = strjoin( json_str, newline );
json_str = strjoin( [ json_str newline ], "" );

end

