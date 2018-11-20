function objectives = read_objective_variables( path )

objectives = struct2table( read_json_file( path ) );
objectives.interpolation_method = objective_interpolation_methods_from_types( objectives.type );

end