function usrp = plot_sample_data( sample_file_name )

if nargin < 1
    sample_file_name = 'steering_column_mount_data.mat';
end

results = load( sample_file_name );
[ ~, data_name, ~ ] = fileparts( sample_file_name );
data = results.(data_name);
data.Properties.UserData.ObjectiveVariablesPath = which( data.Properties.UserData.ObjectiveVariablesPath );
data.Properties.UserData.StlPath = which( data.Properties.UserData.StlPath );
data.Properties.UserData.OptionsPath = which( data.Properties.UserData.OptionsPath );

figure_resolution_px = 600;
usra = UnitSphereResponseAxes();
usrd = UnitSphereResponseData( data, figure_resolution_px );
usrp = UnitSphereResponsePlot( usrd, usra, figure_resolution_px );

end

