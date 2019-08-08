function json = read_json_file( file )

json = jsondecode( read_text_file( file ) );

end

