classdef SolidificationDashboard < modeler.Dashboard
    
    methods ( Access = public )
        
        function obj = SolidificationDashboard( ...
                fdm_mesh, ...
                physical_properties, ...
                solver, ...
                problem, ...
                iterator, ...
                results, ...
                indices_of_interest ...
                )
            
            assert( isa( solver, 'modeler.super.Solver' ) );
            assert( isa( problem, 'modeler.super.Problem' ) );
            assert( isa( iterator, 'modeler.super.Iterator' ) );
            
            obj.mesh = fdm_mesh;
            obj.pp = physical_properties;
            obj.solver = solver;
            obj.problem = problem;
            obj.iterator = iterator;
            obj.results = results;
            
            obj.compute_subplot_locations();
            
            obj.fh = figure();
            obj.fh.Position = [ 50 50 1200 800 ];
            obj.fh.Name = 'Solidification FDM Dashboard';
            obj.fh.NumberTitle = 'off';
            obj.fh.MenuBar = 'none';
            obj.fh.ToolBar = 'none';
            obj.fh.DockControls = 'off';
            
            obj.profile_axhs = gobjects( obj.PROFILE_COUNT, 1 );
            obj.profile_phs = gobjects( obj.PROFILE_COUNT, 1 );
            obj.profile_init_phs = gobjects( obj.PROFILE_COUNT, 1 );
            
            obj.histogram_axhs = gobjects( obj.HISTOGRAM_COUNT, 1 );
            obj.histogram_phs = gobjects( obj.HISTOGRAM_COUNT, 1 );
            
            obj.setup_temperature_profiles( indices_of_interest );
            
            stats = obj.get_temperature_field_statistics( ...
                obj.mesh, ...
                obj.pp, ...
                obj.pp.generate_initial_temperature_field( obj.mesh )...
                );
            obj.setup_time_temperature_curves( ...
                1, ...
                stats, ...
                obj.get_temperature_field_statistics() ...
                );
            
            obj.setup_histogram( 1 );
            obj.setup_histogram( 2 );
            
            obj.setup_labels( ...
                obj.get_label_values( 'label' ), ...
                obj.get_label_values( 'formatspec' ), ...
                obj.get_label_values( '', iterator ) ...
                );
            
        end
        
        
        function update( obj )
            
            temps = obj.problem.get_temperature();
            obj.update_temperature_profiles( temps );
            
            stats = obj.get_temperature_field_statistics( ...
                obj.mesh, ...
                obj.pp, ...
                temps ...
                );
            obj.update_time_temperature_curves( ...
                obj.iterator.get_elapsed_simulation_time(), ...
                stats ...
                );
            
            obj.update_histogram( ...
                1, ...
                temps - obj.problem.get_previous_temperature() ...
                );
            
            obj.update_histogram( ...
                2, ...
                temps( obj.pp.is_primary_melt( obj.mesh ) ) ...
                );
            
            obj.update_labels( ...
                obj.get_label_values( '', obj.iterator ) ...
                );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        mesh
        pp
        solver
        problem
        iterator
        results
        
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
        curve_marked_temperature_phs
        
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
            for i = 1 : numel( obj.curve_marked_temperature_phs )
                
                set( ...
                    obj.curve_marked_temperature_phs, ...
                    'XData', ...
                    obj.curve_axh.XLim ...
                    );
                
            end
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
            if new_extreme > 0 && all( values >= 0, 'all' )
                h.XLim = [ 0 new_extreme ];
            elseif new_extreme > 0
                h.XLim = [ -new_extreme new_extreme ];
            else
                h.XLim = [ -eps eps ];
            end
            edges = linspace( h.XLim( 1 ), h.XLim( 2 ), obj.HISTOGRAM_EDGE_COUNT );
            histogram( h, values( : ), edges );
            h.YScale = 'log';
            h.YLim = [ 0.9 numel( obj.mesh ) ];
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
        
        
        function setup_temperature_profiles( obj, center )
            
            shape = size( obj.mesh );
            bb_lengths = padarray( shape, 1, 0, 'pre' ) .* obj.pp.get_space_step();
            u_init = obj.pp.generate_initial_temperature_field( obj.mesh );
            
            for i = 1 : obj.PROFILE_COUNT
                
                obj.profile_axhs( i ) = subplot( ...
                    obj.SUBPLOT_HEIGHT, ...
                    obj.SUBPLOT_WIDTH, ...
                    obj.SUBPLOT_PROFILES( i ) ...
                    );
                hold( obj.profile_axhs( i ), 'on' );
            
                obj.profile_indices{ i } = { center( 1 ) center( 2 ) center( 3 ) };
                obj.profile_indices{ i }{ i } = 1 : shape( i );
                
                range = bb_lengths( :, i );
                obj.profile_axhs( i ).XLim = range;
                obj.profile_axhs( i ).YLim = obj.pp.get_temperature_range();
                obj.profile_xs{ i } = ...
                    linspace( range( 1 ), range( 2 ), shape( i ) );
                
                obj.profile_phs( i ) = obj.null_plot( obj.profile_axhs( i ) );
                obj.profile_phs( i ).Color = 'k';
                obj.profile_phs( i ).LineStyle = '-';
                
                obj.draw_temperature_markers( obj.profile_axhs( i ) );
                
            end
            obj.update_temperature_profiles( u_init );
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
            obj.curve_axh.YLim = obj.pp.get_temperature_range();
            hold( obj.curve_axh, 'on' );
            obj.update_time_temperature_curves( 0, initial_temperatures );
            obj.curve_axh.XLim = [ 0 first_time_step ];
            obj.curve_marked_temperature_phs = obj.draw_temperature_markers( obj.curve_axh );
            drawnow();
            
        end
        
        
        function setup_histogram( obj, histogram_id )
            
            assert( histogram_id <= obj.HISTOGRAM_COUNT );
            h = subplot( ...
                obj.SUBPLOT_HEIGHT, ...
                obj.SUBPLOT_WIDTH, ...
                obj.SUBPLOT_HISTOGRAMS{ histogram_id } ...
                );
            obj.set_histogram_axh( histogram_id, h );
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
        
        
        function phs = draw_temperature_markers( obj, axh )
            
            phs( 1 ) = obj.draw_horizontal_line( ...
                axh, ...
                obj.pp.get_liquidus_temperature(), ...
                'k', ':' ...
                );
            phs( 2 ) = obj.draw_horizontal_line( ...
                axh, ...
                obj.pp.get_solidus_temperature(), ...
                'k', ':' ...
                );
            phs( 3 ) = obj.draw_horizontal_line( ...
                axh, ...
                obj.pp.get_feeding_effectivity_temperature(), ...
                'r', ':' ...
                );
            
        end
        
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
        
        
        function values = get_temperature_field_statistics( ...
                obj, ...
                fdm_mesh, ...
                physical_properties, ...
                u ...
                )
            
            % colors
            COUNT = 3;
            if nargin == 1
                values = [ ...
                    0 0 1; ...
                    0 1 0; ...
                    1 0 0 ...
                    ];
                assert( size( values, 1 ) == COUNT );
            else
                is_melt = physical_properties.is_primary_melt( fdm_mesh );
                values = [ ...
                    min( u( is_melt ) ), ...
                    mean( u( is_melt ) ), ...
                    max( u( is_melt ) ) ...
                    ];
                assert( numel( values ) == COUNT );
            end
            
        end
        
        
        function values = get_label_values( obj, return_indicator, iterator )
            
            if nargin > 1 && strcmpi( return_indicator, 'label' )
                values = { ...
                    'Step', ...
                    'Iterations', ...
                    'PCG Count', ...
                    'Computation time (s)', ...
                    'Simulation time (s)', ...
                    'Solidification time (s)' ...
                    };
            elseif nargin > 1 && strcmpi( return_indicator, 'formatspec' )
                values = { ...
                    '%i', ...
                    '%i', ...
                    '%i', ...
                    '%.2f', ...
                    '%.2f', ...
                    '%.2f' ...
                    };
            else
                values = [ ...
                    iterator.get_step_count() ...
                    iterator.get_total_iterations() ...
                    iterator.get_total_solver_count() ...
                    iterator.get_elapsed_computation_time() ...
                    iterator.get_elapsed_simulation_time() ...
                    nan ...obj.overall_solidification_time ...
                    ];
            end
            
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

