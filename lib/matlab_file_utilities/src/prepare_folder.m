function prepare_folder( folder )
% makes sure an empty folder exists at input
% this operation cleans folder if it exists and is not empty!

assert( ~contains( folder, '..' ) );
assert( ~isfile( folder ) );

if ~isfolder( folder )
    mkdir( folder );
else
    clear_folder( folder );
end

end

