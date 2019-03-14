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

%data.draft_metric( data.draft_metric > 0 ) = - ( 1 ./ log10( data.draft_metric( data.draft_metric > 0 ) ) );

figure_resolution_px = 600;
color_map = interp1( [ 0; 1 ], repmat( [ 0.3; 0.9 ], [ 1 3 ] ), linspace( 0, 1, 256 ) );
grid_color = [ 0 0 0 ];
usra = UnitSphereResponseAxes( color_map, grid_color );
usrd = UnitSphereResponseData( data, figure_resolution_px );
usrp = UnitSphereResponsePlot( usrd, usra, figure_resolution_px );
bg_color = [ 1 1 1 ];
usrp.set_background_color( bg_color );

end

