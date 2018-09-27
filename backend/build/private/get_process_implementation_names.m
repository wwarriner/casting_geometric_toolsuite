function [ names, class_names ] = get_process_implementation_names()

listing = get_files_with_extension( process_implementation_path(), '.m' );
[ ~, class_filenames, ~ ] = cellfun( @(x) fileparts( x ), listing.name, 'uniformoutput', false );
class_filenames( strcmpi( class_filenames, 'process_implementation_path' ), : ) = [];
class_filenames( strcmpi( class_filenames, 'readme' ), : ) = [];
count = numel( class_filenames );
names = cell( count, 1 );
class_names = cell( count, 1 );
for i = 1 : count

    names{ i } = eval( [ class_filenames{ i } '.NAME' ] );
    class_names{ i } = class_filenames{ i };

end

end

