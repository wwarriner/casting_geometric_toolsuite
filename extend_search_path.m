function extend_search_path()

addpath( genpath( pwd ) );

removed_paths = { ...
    '.git' ...
    };    
cellfun( @(x) rmpath( genpath( fullfile( pwd, x ) ) ), removed_paths );

end