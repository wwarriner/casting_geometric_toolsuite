function listing = get_files_with_extension( scan_dir, scan_ext )

assert( exist( scan_dir, 'dir' ) == 7 )
if ~startsWith( scan_ext, '.' )
    scan_ext = [ '.' scan_ext ];
end

listing = struct2table( dir( scan_dir ) );
listing( listing.isdir == 1, : ) = [];
[ ~, ~, exts ] = cellfun( @fileparts, [ listing.name ], 'uniformoutput', 0 );
have_ext = cell2mat( cellfun( @(x) strcmpi( x, scan_ext ), exts, 'uniformoutput', 0 ) );
listing( ~have_ext, : ) = [];

end

