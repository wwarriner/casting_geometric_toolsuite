function full_paths = get_full_paths_from_listing( listing )

f = [ listing.folder ];
n = [ listing.name ];
full_paths = cellfun( @fullfile, f, n, 'uniformoutput', 0 );

end

