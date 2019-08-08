function dir_table = remove_dots( dir_table )

dots = ismember( { '.', '..' }, dir_table.name );
dir_table( dots, : ) = [];

end

