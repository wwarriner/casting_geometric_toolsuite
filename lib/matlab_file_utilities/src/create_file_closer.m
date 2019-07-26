function file_closer = create_file_closer( fid )

file_closer = onCleanup( @()silent_fclose( fid ) );

end


function silent_fclose( fid )

try
    fclose( fid );
catch e %#ok<NASGU>
    % do nothing
end

end

