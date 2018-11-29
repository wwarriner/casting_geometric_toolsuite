function usrp = plot_sample_data( sample_file_name )

results = load( sample_file_name );

figure_resolution_px = 600;
usra = UnitSphereResponseAxes();
usrd = UnitSphereResponseData( ...
    results.(data_name), ...
    figure_resolution_px ...
    );
usrp = UnitSphereResponsePlot( usrd, usra, figure_resolution_px );

end

