function contents = get_contents( folder )

assert( isfolder( folder ) );

contents = struct2table( dir( folder ) );
contents = remove_dots( contents );

end

