function names = affix_table_names( names, prefix, suffix, delimiter )

if nargin < 4
    
    delimiter = '_';
    
end

names = cellfun( ...
    @(x) affix_name( x, prefix, suffix, delimiter ), ...
    names, ...
    'UniformOutput', false ...
    );

end

function name = affix_name( name, prefix, suffix, delimiter )

if ~isempty( prefix )
    
    name = [ prefix delimiter name ];
    
end

if ~isempty( suffix )
    
    name = [ name delimiter suffix ];
    
end

end