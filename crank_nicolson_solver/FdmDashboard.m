classdef FdmDashboard < handle
    
    methods ( Access = public )
        
        function obj = FdmDashboard( ...
                temperature_range, ...
                feeding_effectivity_temperature ...
                )
            
            obj.compute_subplot_locations();
            
            obj.temperature_range = temperature_range;
            obj.feeding_effectivity_temperature = feeding_effectivity_temperature;
            
            obj.fh = figure();
            obj.fh.Position = [ 50 50 1200 800 ];
            obj.fh.Name = 'Solidification FDM Dashboard';
            obj.fh.MenuBar = 'none';
            obj.fh.ToolBar = 'none';
            obj.fh.DockControls = 'off';
            
            obj.profile_axhs = gobjects( obj.PROFILE_COUNT, 1 );
            obj.profile_phs = gobjects( obj.PROFILE_COUNT, 1 );
            obj.profile_init_phs = gobjects( obj.PROFILE_COUNT, 1 );
            
            obj.histogram_axhs = gobjects( obj.HISTOGRAM_COUNT, 1 );
            obj.histogram_phs = gobjects( obj.HISTOGRAM_COUNT, 1 );
            
        end
        
        
        function setup_temperature_profiles( obj, ...
                x_bounds, ...
                shape, ...
                center, ...
                initial_temperatures ...
                )
            
            for i = 1 : obj.PROFILE_COUNT
                
                obj.profile_axhs( i ) = subplot( ...
                    obj.SUBPLOT_HEIGHT, ...
                    obj.SUBPLOT_WIDTH, ...
                    obj.SUBPLOT_PROFILES( i ) ...
                    );
                hold( obj.profile_axhs( i ), 'on' );
            
                obj.profile_indices{ i } = { center( 1 ) center( 2 ) center( 3 ) };
                obj.profile_indices{ i }{ i } = 1 : shape( i );
                
                range = x_bounds( :, i );
                obj.profile_axhs( i ).XLim = range;
                obj.profile_axhs( i ).YLim = obj.temperature_range;
                obj.profile_xs{ i } = ...
                    linspace( range( 1 ), range( 2 ), shape( i ) );
                
                obj.profile_phs( i ) = obj.null_plot( obj.profile_axhs( i ) );
                obj.profile_phs( i ).Color = 'k';
                obj.profile_phs( i ).LineStyle = '-';
                
                obj.draw_horizontal_line( ...
                    obj.profile_axhs( i ), ...
                    obj.feeding_effectivity_temperature, ...
                    'k', ':' ...
                    );
                
            end
            obj.update_temperature_profiles( initial_temperatures );
            for i = 1 : obj.PROFILE_COUNT
                
                obj.profile_init_phs( i ) = obj.profile_phs( i );
                obj.profile_phs( i ) = obj.null_plot( obj.profile_axhs( i ) );
                obj.profile_phs( i ).Color = 'r';
                obj.profile_phs( i ).LineStyle = '-';
                
            end
            drawnow();
            
        end
        
        
        function setup_time_temperature_curves( ...
                obj, ...
                first_time_step, ...
                initial_temperatures, ...
                colors ...
                )
            
            obj.curve_count = numel( initial_temperatures );
            obj.curve_axh = subplot( ...
                obj.SUBPLOT_HEIGHT, ...
                obj.SUBPLOT_WIDTH, ...
                obj.SUBPLOT_CURVES ...
                );
            obj.curve_colors = colors;
            obj.curve_axh.YLim = obj.temperature_range;
            hold( obj.curve_axh, 'on' );
            obj.update_time_temperature_curves( 0, initial_temperatures );
            obj.curve_axh.XLim = [ 0 first_time_step ];
            obj.curve_fe_ph = obj.draw_horizontal_line( ...
                    obj.curve_axh, ...
                    obj.feeding_effectivity_temperature, ...
                    'k', ':' ...
                    );
            drawnow();
            
        end
        
        
        function setup_histogram( obj, histogram_id, element_count )
            
            assert( histogram_id <= obj.HISTOGRAM_COUNT );
            h = subplot( ...
                obj.SUBPLOT_HEIGHT, ...
                obj.SUBPLOT_WIDTH, ...
                obj.SUBPLOT_HISTOGRAMS{ histogram_id } ...
                );
            obj.set_histogram_axh( histogram_id, h );
            obj.element_count = element_count;
            obj.histogram_extremes( histogram_id ) = eps;
            obj.histogram_phs( histogram_id ) = obj.null_plot( h );
            obj.histogram_phs( histogram_id ).Color = 'k';
            
        end
        
        
        function setup_labels( obj, labels, formatspecs, initial_values )
            
            assert( numel( labels ) == numel( initial_values ) );
            
            obj.label_count = numel( labels );
            obj.labels = labels;
            obj.label_formatspecs = formatspecs;
            obj.label_hs = gobjects( obj.label_count, 1 );
            
            WIDTH = obj.fh.Position( 3 ) ./ obj.SUBPLOT_WIDTH;
            X_BUFFER = 10;
            X = obj.fh.Position( 3 ) - WIDTH + X_BUFFER;
            HEIGHT = 30;
            Y_BUFFER = 50;
            Y_SPACING = 10;
            Y_START = obj.fh.Position( 4 ) - Y_BUFFER;
            for i = 1 : obj.label_count
                
                Y = Y_START - i * ( HEIGHT + Y_SPACING );
                obj.label_hs( i ) = uicontrol( ...
                    obj.fh, ...
                    'style', 'text', ...
                    'string', '', ...
                    'horizontalalignment', 'left', ...
                    'fontsize', 20, ...
                    'position', [ X Y WIDTH HEIGHT ] ...
                    );
                
            end
            obj.update_labels( initial_values );
            
        end
        
        
        function update_temperature_profiles( obj, temperatures )
            
            for i = 1 : obj.PROFILE_COUNT
                
                set( ...
                    obj.profile_phs( i ), ...
                    'XData', ...
                    obj.profile_xs{ i }, ...
                    'YData', ...
                    squeeze( temperatures( obj.profile_indices{ i }{ : } ) ) ...
                    );
                
            end
            drawnow();
            
        end
        
        
        function update_time_temperature_curves( obj, time, values )
            
            for i = 1 : obj.curve_count
                
                plot( ...
                    obj.curve_axh, ...
                    time, ...
                    values( i ), ...
                    'color', obj.curve_colors( i, : ), ...
                    'linestyle', 'none', ...
                    'marker', '.' ...
                    );
                
            end
            if time > 0
                obj.curve_axh.XLim = [ 0 time ];
            end
            set( ...
                obj.curve_fe_ph, ...
                'XData', ...
                obj.curve_axh.XLim ...
                );
            drawnow();
            
        end
        
        
        function update_histogram( obj, histogram_id, values )
            
            assert( histogram_id <= obj.HISTOGRAM_COUNT );
            
            h = obj.get_histogram_axh( histogram_id );
            current_extreme = max( abs( values( : ) ) );
            obj.histogram_extremes( histogram_id ) = max( ...
                current_extreme, ...
                obj.histogram_extremes( histogram_id ) ...
                );
            new_extreme = obj.histogram_extremes( histogram_id );
            if new_extreme > 0
                h.XLim = [ -new_extreme new_extreme ];
            else
                h.XLim = [ -eps eps ];
            end
            edges = linspace( h.XLim( 1 ), h.XLim( 2 ), obj.HISTOGRAM_EDGE_COUNT );
            histogram( h, values( : ), edges );
            h.YScale = 'log';
            h.YLim = [ 0.9 obj.element_count ];
            drawnow();
            
        end
        
        
        function update_labels( obj, values )
            
            assert( numel( values ) == obj.label_count );
            for i = 1 : obj.label_count
                
                obj.label_hs( i ).String = sprintf( ...
                    [ '%s: ' obj.label_formatspecs{ i } ], ...
                    obj.labels{ i }, ...
                    values( i ) ...
                    );
                
            end
            drawnow();
            
        end
        
    end
    
    
    properties ( Access = private )
        
        temperature_range
        feeding_effectivity_temperature
        element_count
        
        fh
        
        profile_axhs
        profile_init_phs
        profile_phs
        profile_indices
        profile_xs
        profile_ys
        
        curve_count
        curve_axh
        curve_colors
        curve_fe_ph
        
        histogram_axhs
        histogram_extremes
        histogram_phs
        
        label_count
        labels
        label_formatspecs
        label_hs
        
        SUBPLOT_PROFILES
        SUBPLOT_CURVES
        SUBPLOT_HISTOGRAMS
        
    end
    
    
    properties ( Access = private, Constant )
        
        SUBPLOT_WIDTH = 3
        SUBPLOT_HEIGHT = 6
        
        PROFILE_COUNT = 3;
        
        HISTOGRAM_COUNT = 2;
        HISTOGRAM_EDGE_COUNT = 50;
        
    end
    
    
    methods ( Access = private )
        
        function compute_subplot_locations( obj )
            
            obj.SUBPLOT_PROFILES = ( 0 : 2 ) .* obj.SUBPLOT_WIDTH + 1;
            obj.SUBPLOT_CURVES = obj.SUBPLOT_PROFILES + 1;
            obj.SUBPLOT_HISTOGRAMS = { ...
                obj.SUBPLOT_PROFILES + obj.SUBPLOT_HEIGHT + obj.SUBPLOT_WIDTH, ...
                obj.SUBPLOT_PROFILES + obj.SUBPLOT_HEIGHT + obj.SUBPLOT_WIDTH + 1 ...
                };
            assert( numel( obj.SUBPLOT_HISTOGRAMS ) == obj.HISTOGRAM_COUNT );
            
        end
        
        
        function set_histogram_axh( obj, id, h )
            
            obj.histogram_axhs( id ) = h;
            
        end
        
        
        function h = get_histogram_axh( obj, id )
            
            h = obj.histogram_axhs( id );
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function ph = null_plot( axh )
            
            ph = plot( axh, 0, 0 );
            
        end
        
        function lh = draw_horizontal_line( axh, y, color, style )
            
            lh = line( axh, axh.XLim, [ y y ], 'color', color, 'linestyle', style );
            
        end
        
    end
    
end

