% @append_to_variable_names is a function that prepends and postpends strings
% onto the variable names of a table. The resulting variable names must still
% adhere to the rules for table variable names.
%
% Inputs:
% - @t is a table.
% - @opt is a struct. At least one of the fields "pre" or "post" must be
% present. The contents of each must be convertible to a string scalar, or 
% string vector with the same number of elements as variable names in @t. The 
% contents of "pre" are prepended to the variable names of @t, while the
% contents of "post" are postpended. The field "delimiter" is optional, and its
% contents must be convertible to a scalar string. The contents of "delimiter"
% are used between "pre" and the variable names, and "post" and the variable
% names. The default value of "pre" and "post" is "", and the default value of
% "delimiter" is "_".
%
% Outputs:
% - @t is the same table as input, but with the variable names modified as
% described above.

function t = append_to_variable_names( t, opt )

assert( isstruct( opt ) );
assert( isfield( opt, "pre" ) | isfield( opt, "post" ) );
if isfield( opt, "delimiter" )
    assert( isstring( opt.delimiter ) | ischar( opt.delimiter ) | iscell( opt.delimiter ) );
    opt.delimiter = string( opt.delimiter );
    assert( numel( opt.delimiter ) == 1 );
else
    opt.delimiter = "_";
end
if isfield( opt, "pre" )
    assert( isstring( opt.pre ) | ischar( opt.pre ) | iscell( opt.pre ) );
    opt.pre = string( opt.pre );
else
    opt.pre = "";
end
if isfield( opt, "post" )
    assert( isstring( opt.post ) | ischar( opt.post ) | iscell( opt.post ) );
    opt.post = string( opt.post );
else
    opt.post = "";
end

names = string( t.Properties.VariableNames );
count = numel( names );

pre_count = numel( opt.pre );
assert( pre_count == 1 | pre_count == count );

post_count = numel( opt.post );
assert( post_count == 1 | post_count == count );

if opt.pre ~= ""
    names = opt.pre + opt.delimiter + names;
end
if opt.post ~= ""
    names = names + opt.delimiter + opt.post;
end

t.Properties.VariableNames = names;

end

