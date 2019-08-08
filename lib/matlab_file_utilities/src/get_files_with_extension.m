function contents = get_files_with_extension( contents, ext )

if ~startsWith( ext, '.' )
    ext = [ '.' ext ];
end
contents( contents.isdir == 1, : ) = [];
[ ~, ~, exts ] = cellfun( @fileparts, [ contents.name ], 'uniformoutput', 0 );
has_ext = cell2mat( cellfun( @(x)strcmpi(x,ext), exts, 'uniformoutput', 0 ) );
contents( ~has_ext, : ) = [];

end

