function generate_csvs_on_hpc( input_path, option_path, angles, index, output_mat_dir )

opt = Optimizer( option_path, input_path );
results = opt.determine_results_as_table( angles );
filename = [ 'results_' opt.get_name() '_' sprintf( '%i', index ) '.csv' ];
writetable( results, fullfile( output_mat_dir, filename ) );

end