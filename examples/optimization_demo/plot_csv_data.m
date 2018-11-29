function usrp = plot_csv_data( sample_name )

data_file = [ sample_name '.mat' ];
results = load( data_file );

figure_resolution_px = 600;
usra = UnitSphereResponseAxes();
usrd = UnitSphereResponseData( ...
    results.(data_name), ...
    figure_resolution_px ...
    );
usrp = UnitSphereResponsePlot( usrd, usra, figure_resolution_px );

end

