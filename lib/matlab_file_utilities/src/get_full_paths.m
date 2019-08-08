function paths = get_full_paths( contents )

paths = cellfun( ...
    @fullfile, ...
    contents.folder, ...
    contents.name, ...
    'uniformoutput', false ...
    );

end

