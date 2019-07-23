function empty = is_folder_empty( folder )
% returns true if not a folder

if isfolder( folder )
    contents = get_contents( folder );
    empty = isempty( contents );
else
    empty = true;
end

end

