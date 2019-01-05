classdef (Sealed) ObjectiveVariables < handle
    
    methods ( Access = public )
        
        function obj = ObjectiveVariables( varargin )
            
            if numel( varargin ) == 1 ...
                    && ( ischar( varargin{ 1 } ) || isstring( varargin{ 1 } ) )
                path = varargin{ 1 };
                obj.variables = obj.read_objective_variables( path );
            elseif numel( varargin ) == 2
                obj.variables.title = varargin{ 1 };
                obj.variables.display = obj.variables.title;
                obj.variables.interpolation_method = varargin{ 2 };
            else
                assert( false );
            end
            
            
        end
        
        
        function titles = get_display_titles( obj )
            
            titles = obj.variables.display;
            
        end
        
        
        function title = get_display_title( obj, index )
            
            title = obj.variabls.display{ index };
            
        end
        
        
        function titles = get_titles( obj )
            
            titles = obj.variables.title;
            
        end
        
        
        function title = get_title( obj, index )
            
            title = obj.variables.title{ index };
            
        end
        
        
        function methods = get_interpolation_methods( obj )
            
            methods = obj.variables.interpolation_method;
            
        end
        
        
        function method = get_interpolation_method( obj, index )
            
            method = obj.variables.interpolation_method{ index };
            
        end
        
        
        % retrieval function must take a process name and return the desired process object
        function value = evaluate( obj, index, retrieval_function, dimension, gravity_direction ) %#ok<INUSD>
            
            metric_fn = eval( sprintf( ...
                '@(property)%s;\n', ...
                obj.get_metric( index ) ...
                ) ); %#ok<NASGU>
            process = eval( sprintf( '%s.NAME', obj.get_process( index ) ) );
            process = retrieval_function( process ); %#ok<NASGU>
            property = obj.get_property( index );
            value = eval( sprintf( 'metric_fn( process.%s )', property ) );
            
        end
        
        
        function count = get_objective_count( obj )
            
            count = size( obj.variables, 1 );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        variables
        
    end
    
    
    methods ( Access = private )
        
        function process = get_process( obj, index )
            
            process = obj.variables{ index, 'process' }{ 1 };
            
        end
        
        
        function property = get_property( obj, index )
            
            
            property = obj.variables{ index, 'property' }{ 1 };
            
        end
        
        
        function metric = get_metric( obj, index )
            
            
            metric = obj.variables{ index, 'metric' }{ 1 };
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function variables = read_objective_variables( path )
            
            variables = struct2table( read_json_file( path ) );
            variables.interpolation_method = ...
                ObjectiveVariables.types_to_interp_methods( variables.type );
            
        end
        
        
        function methods = types_to_interp_methods( types )
            
            types_to_interpolation_methods_map = containers.Map( ...
                { ...
                'categorical', ...
                'continuous' ...
                }, ...
                { ...
                'nearest', ...
                'natural' ...
                } ...
                );
            methods = types;
            for i = 1 : numel( types )
                
                methods{ i } = types_to_interpolation_methods_map( types{ i } );
                
            end
            
        end
        
    end
    
end

