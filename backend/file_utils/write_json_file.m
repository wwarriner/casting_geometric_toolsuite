function write_json_file( path, json_object )

write_file( path, jsonencode( json_object ) );

end

