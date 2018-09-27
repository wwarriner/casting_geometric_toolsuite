function clear_directory_contents( target_dir )
    
    contents = dir( target_dir );
    for i = 1 : length( contents( : ) )
        
        content = contents( i );
        if ~content.isdir
            
            file_path = fullfile( content.folder, content.name );
            delete( file_path );
            
        elseif ~( strcmp( content.name, '..' ) ...
            || strcmp( content.name, '.' ) )
            
            rmdir( fullfile( content.folder, content.name ), 's' );
            
        end
        
    end


end

