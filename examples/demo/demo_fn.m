function demo_fn( settings_file, input_file, output_folder )
%% OPTIONS
settings = Settings( settings_file );
settings.processes.Casting.input_file = input_file;
settings.manager.output_folder = output_folder;

%% ANALYSIS
pm = ProcessManager( settings );
pm.run();
pm.write_all();
pm.write_summary();

end