function s = make_title( s )

was_char = false;
if ischar( s )
    s = string( s );
    was_char = true;
end

bad_pattern = "([^0-9a-zA-Z]*)";
s = lower( regexprep( s, bad_pattern, " " ) );

initial_pattern = "([a-z])[0-9a-z]*";
start = regexp( s, initial_pattern );
for i = 1 : numel( start )
    t = s{ i };
    st = start{ i };
    for j = 1 : numel( st )
        t( st( j ) ) = upper( t( st( j ) ) );
    end
    s{ i } = t;
end

if was_char
    s = char( s );
end

end

