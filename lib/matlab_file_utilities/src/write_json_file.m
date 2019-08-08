function write_json_file( file, json, do_pretty_print )

if nargin < 3
    do_pretty_print = true;
end

assert( islogical( do_pretty_print ) );
assert( isscalar( do_pretty_print ) );

json_str = jsonencode( json );
if do_pretty_print
    json_str = pretty_print_json( json_str );
end
write_text_file( file, json_str );

end

