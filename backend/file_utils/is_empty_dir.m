function empty = is_empty_dir( path )
% returns true if not a folder

if isfolder( path )
    contents = dir( path );
    names = { contents.name };
    found = or( strcmpi( names, '.' ), strcmpi( names, '..' ) );
    contents( found ) = [];
    empty = isempty( contents );
else
    empty = true;
end

end

