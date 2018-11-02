function full_path = prepare_child_dir( parent, child )

full_path = fullfile( parent, child );
prepare_dir( full_path );

end

