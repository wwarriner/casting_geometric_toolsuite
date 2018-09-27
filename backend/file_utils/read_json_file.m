function json_object = read_json_file( path )

json_object = jsondecode( read_file( path ) );

end

