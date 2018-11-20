classdef (Sealed) OrientationBaseCase < handle
    
    methods ( Access = public )
        
        function obj = OrientationBaseCase( ...
                option_path, ...
                stl_path, ...
                objective_variables_path ...
                )
            
            if nargin < 2
                stl_path = '';
            end
            obj.options = Options( ...
                'option_defaults.json', ...
                option_path, ...
                stl_path, ...
                '' ...
                );
            
            if nargin < 3
                objective_variables_path = obj.options.objective_variables_path;
            end
            obj.objective_variables = read_objective_variables( objective_variables_path );
            obj.base_case = obj.generate_base_case( obj.options );
            
        end
        
        
        function results = determine_results( obj, angles )
            
            angles = angles( : ).';
            objectives = obj.determine_objectives( angles );
            results = [ angles objectives ];
            
        end
        
        
        function results = determine_results_as_table( obj, angles )
            
            results = array2table( obj.determine_results( angles ) );
            results.Properties.VariableNames = obj.get_titles();
            
        end
        
        
        function objectives = determine_objectives( obj, angles )
            
            rotated_case = obj.generate_rotated_case( ...
                angles, ...
                obj.base_case, ...
                obj.options ...
                );
            
            DIM = 3;
            UP = 'up';
            
            uc = Undercuts();
            uc.legacy_run( rotated_case.get( Mesh.NAME ), DIM );
            rotated_case.add( uc.NAME, uc );
            pp = PartingPerimeter();
            pp.legacy_run( rotated_case.get( Mesh.NAME ), DIM, true );
            rotated_case.add( pp.NAME, pp );
            wf = Waterfall();
            wf.legacy_run( rotated_case.get( Mesh.NAME ), pp, UP );
            rotated_case.add( wf.NAME, wf );
            
            objective_count = size( obj.objective_variables, 1 );
            objectives = nan( 1, objective_count );
            for i = 1 : objective_count
                
                phrase = [ ...
                    'value = rotated_case.get( %s.NAME ).%s;\n' ...
                    'value = %s;\n' ...
                    ];
                command = sprintf( ...
                    phrase, ...
                    obj.objective_variables{ i, 'process' }{ 1 }, ...
                    obj.objective_variables{ i, 'value' }{ 1 }, ...
                    obj.objective_variables{ i, 'metric' }{ 1 } ...
                    );
                eval( command );
                objectives( i ) = value;
                
            end
            
        end
        
        
        function titles = get_titles( obj )
            
            titles = [ ...
                obj.get_decision_variable_titles() ...
                obj.get_objective_variable_titles() ...
                ];
            
        end
        
        
        function count = get_decision_variable_count( obj )
            
            count = numel( obj.get_decision_variable_titles() );
            
        end
        
        
        function name = get_name( obj )
            
            name = obj.base_case.get( Component.NAME ).name;
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function titles = get_decision_variable_titles()
            
            titles = { 'phi', 'theta' };
            
        end
        
        
        function lb = get_decision_variable_lower_bounds()
            
            [ phi, theta ] = unit_sphere_ranges();
            lb = [ phi( 1 ); theta( 1 ) ];
            
        end
        
        
        function ub = get_decision_variable_upper_bounds()
            
            [ phi, theta ] = unit_sphere_ranges();
            ub = [ phi( 2 ); theta( 2 ) ];
            
        end
        
    end
    
    
    properties ( Access = private )
        
        options
        objective_variables
        decision_variables
        
        base_case
        
    end
    
    
    methods ( Access = private )
        
        function titles = get_objective_variable_titles( obj )
            
            titles = obj.objective_variables{ :, { 'title' } }.';
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function base_case = generate_base_case( options )
            
            base_case = Results();
            objects = { ...
                Component( base_case, options ), ...
                Mesh( base_case, options ), ...
                EdtProfile( base_case, options ), ...
                Segmentation( base_case, options ), ...
                Feeders( base_case, options ) ...
                };
            for i = 1 : numel( objects )
                
                current = objects{ i };
                current.run();
                base_case.add( current.NAME, current );
                
            end
            
        end
        
        
        function rotated_case = generate_rotated_case( ...
                angles, ...
                base_case, ...
                options ...
                )
            
            r = rotator( angles );
            rotated_case = Results();
            rotated_case.add( Component.NAME, base_case.get( Component.NAME ).rotate( r ) );
            mr = Mesh( rotated_case, options );
            mr.run();
            rotated_case.add( Mesh.NAME, mr );
            rotated_case.add( Feeders.NAME, base_case.get( Feeders.NAME ).rotate( r, mr ) );
            
        end
        
    end
    
end

