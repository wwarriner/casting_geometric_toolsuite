function generate_process_implementation_includer( output_path )

[ ~, class_names ] = get_process_implementation_names();
joined_names = join( append( class_names, '', [ '();' newline ] ), '' );
m_file = [ ...
    'function process_implementation_includer()' newline ...
    newline ...
    joined_names{:} ...
    newline ...
    'end' ...
    ];
write_file( fullfile( output_path, 'process_implementation_includer.m' ), m_file );

end
