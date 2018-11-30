classdef (Sealed) OrientationBaseCase < handle
    
    methods ( Access = public )
        
        function obj = OrientationBaseCase( ...
                option_path, ...
                stl_path, ...
                objective_variables ...
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
            
            if ischar( objective_variables ) || isstring( objective_variables )
                obj.objective_variables = ObjectiveVariables( objective_variables );
            else
                obj.objective_variables = objective_variables;
            end
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
        
        
        function base_case = get_base_case( obj )
            
            base_case = obj.base_case;
            
        end
        
        
        function rotated_case = get_rotated_case( obj, angles )
            
            rotated_case = obj.generate_rotated_case( angles );
            
        end
        
        
        function fv = get_rotated_component_fv( obj, angles )
            
            c = obj.base_case.get( Component.NAME );
            rc = c.rotate( obj.create_rotator( angles ) );
            fv = rc.fv;
            
        end
        
        
        function fvs = get_rotated_feeder_fvs( obj, angles )
            
            f = obj.base_case.get( Feeders.NAME );
            fvs = f.rotate_fvs_only( obj.create_rotator( angles ) );
            
        end
        
        
        function center = get_center_of_rotation( obj )
            
            center = obj.base_case.get( Component.NAME ).centroid;
            
        end
        
        
        function objectives = determine_objectives( obj, angles )
            
            rotated_case = obj.get_rotated_case( angles );
            
            DIM = 3;
            GRAVITY_DIRECTION = 'down';
            
            uc = Undercuts();
            uc.legacy_run( rotated_case.get( Mesh.NAME ), DIM );
            rotated_case.add( uc.NAME, uc );
            pp = PartingPerimeter();
            pp.legacy_run( rotated_case.get( Mesh.NAME ), DIM, true );
            rotated_case.add( pp.NAME, pp );
            wf = Waterfall();
            wf.legacy_run( rotated_case.get( Mesh.NAME ), pp, GRAVITY_DIRECTION );
            rotated_case.add( wf.NAME, wf );
            
            objective_count = obj.objective_variables.get_objective_count();
            objectives = nan( 1, objective_count );
            for i = 1 : objective_count
                
                objectives( i ) = obj.objective_variables.evaluate( i, @rotated_case.get, DIM, GRAVITY_DIRECTION );
                
            end
            
        end
        
        
        function titles = get_titles( obj )
            
            titles = [ ...
                obj.get_decision_variable_titles(); ...
                obj.get_objective_variable_titles() ...
                ];
            
        end
        
        
        function name = get_name( obj )
            
            name = obj.base_case.get( Component.NAME ).name;
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        
        function titles = get_decision_variable_titles()
            
            titles = { 'phi'; 'theta' };
            
        end
        
        
        function count = get_decision_variable_count()
            
            count = numel( OrientationBaseCase.get_decision_variable_titles() );
            
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
            
            titles = obj.objective_variables.get_titles();
            
        end
        
        
        function rotated_case = generate_rotated_case( obj, angles )
            
            r = obj.create_rotator( angles );
            rotated_case = Results();
            rotated_case.add( Component.NAME, obj.base_case.get( Component.NAME ).rotate( r ) );
            mr = Mesh( rotated_case, obj.options );
            mr.run();
            rotated_case.add( Mesh.NAME, mr );
            rotated_case.add( Feeders.NAME, obj.base_case.get( Feeders.NAME ).rotate( r, mr ) );
            
        end
        
        
        function rotator = create_rotator( obj, angles )
            
            rotator = Rotator( angles, obj.get_center_of_rotation() );
            
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
        
    end
    
end

