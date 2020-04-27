function check_suitesparse()

if isdeployed()
    return;
end

matches = struct2table( dir( "**/sparse2.mex*" ) );
if isempty( matches )
    throw_exception()
end

matches = matches( ~contains( matches.folder, "private" ), : );
folders = unique( matches.folder );
found = false;
for i = 1 : numel( folders )
    if contains( path(), folders{ i } )
        found = true;
        break;
    end
end

if ~found
    throw_exception()
end

end


function throw_exception()
    
    ME = MException( ...
        "check_suitesparse:notFound", ...
        "Could not find suitesparse.\n" ...
        + "Please get from https://github.com/wwarriner/suitesparse_cholmod.\n" ...
        + "If on Windows, you may need Visual Studio to compile.\n" ...
        );
    throw( ME )
    
end