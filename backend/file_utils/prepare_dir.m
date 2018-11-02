function prepare_dir( path )

if contains( path, '..' )
    
    error( 'path must not contain ''..''' );
    
end

if ~isfolder( path )
    
    mkdir( path );
    
else
    
    clear_directory_contents( path );
    
end

end

