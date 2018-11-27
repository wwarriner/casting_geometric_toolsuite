classdef (Sealed) ObjectiveVariables < handle
    
    methods ( Access = public )
        
        function obj = ObjectiveVariables( varargin )
            
            if numel( varargin ) == 1 ...
                    && ( ischar( varargin{ 1 } ) || isstring( varargin{ 1 } ) )
                path = varargin{ 1 };
                obj.variables = obj.read_objective_variables( path );
            elseif numel( varargin ) == 2
                obj.variables.title = varargin{ 1 };
                obj.variables.interpolation_method = varargin{ 2 };
            else
                assert( false );
            end
                
            
        end
        
        
        function titles = get_titles( obj )
            
            titles = obj.variables.title;
            
        end
        
        
        function title = get_title( obj, index )
            
            title = obj.variables.title{ index };
            
        end
        
        
        function method = get_interpolation_method( obj, index )
            
            method = obj.variables.interpolation_method{ index };
            
        end
        
        
        function count = get_objective_count( obj )
            
            count = size( obj.variables, 1 );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        variables
        
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

