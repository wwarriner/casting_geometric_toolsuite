function full_path = prepare_child_dir( parent, child )

full_path = fullfile( parent, child );
if contains( full_path, '..' )
    
    error( 'path must not contain ''..''' );
    
end

if ~isfolder( full_path )
    
    mkdir( full_path );
    
else
    
    clear_directory_contents( full_path );
    
end

end

