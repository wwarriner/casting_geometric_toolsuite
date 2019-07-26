function folder = prepare_child_folder( parent, child )

folder = fullfile( parent, child );
prepare_folder( folder );

end

