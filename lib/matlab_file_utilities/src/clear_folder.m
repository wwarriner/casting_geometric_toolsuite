function clear_folder( folder )

contents = get_contents( folder );
for i = 1 : height( contents )
    content = contents( i, : );
    path = fullfile( content.folder{:}, content.name{:} );
    if content.isdir
        rmdir( path, 's' );
    else
        delete( path );
    end
end

end

