%{

@make_title

Description:
This function converts strings to title-like strings. Every word in the 
string has the first character capitalized if it is a letter, and every
other letter character set to lower case. All other characters are removed.

Inputs:
 - @s, a string-like array. May be a string array, a character array, or a
 cell array of character vectors.

Outputs:
 - @s, a string-like array of the same type as the input, converted as
 described above.

Examples:
 - "a tAle of TWO cities" -> "A Tale Of Two Cities"
 - "123 ABC" -> "123 Abc"

%}

function s = make_title( s )

STRING = "string";
CHAR = "char";
CELLSTR = "cellstr";

if isstring( s )
    input_type = STRING;
elseif ischar( s )
    input_type = CHAR;
elseif iscellstr( s )
    input_type = CELLSTR;
else
    assert( false );
end
s = string( s );
    
bad_pattern = "([^0-9a-zA-Z]*)";
s = regexprep( s, bad_pattern, " " );
s = lower( s );

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

switch input_type
    case CHAR
        s = char( s );
    case CELLSTR
        s = cellstr( s );
    case STRING
        s = string( s );
    otherwise
        assert( false );
end

end

