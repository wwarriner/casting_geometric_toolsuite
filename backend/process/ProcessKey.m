classdef ProcessKey < handle
    
    methods ( Access = public )
        
        function obj = ProcessKey( ...
                class_name, ...
                parting_dimension, ...
                gravity_direction ...
                )
            
            if nargin < 3
                gravity_direction = [];
            end
            
            if nargin < 2
                parting_dimension = [];
            end
            
            obj.name = class_name;
            obj.parting_dimension = parting_dimension;
            obj.gravity_direction = gravity_direction;
            
        end
        
        
        function instance = create_instance( obj, varargin )
            
            instance = feval( obj.name, varargin{ : } );
            
            if instance.is_orientation_dependent()
                instance.set_parting_dimension( obj.parting_dimension );
            end
            
            if instance.has_gravity_direction()
                instance.set_gravity_direction( obj.gravity_direction );
            end
            
        end
        
        
        function key = to_string( obj )
            
            parts = { obj.name };
            if ~isempty( obj.parting_dimension )
                parts = [ parts, num2str( obj.parting_dimension, '%i' ) ];
            end
            if ~isempty( obj.gravity_direction )
                parts = [ parts, obj.gravity_direction ];
            end
            key = strjoin( parts, '_' );
            
        end
        
    end
    
    
    properties ( Access = private )
        
        name
        parting_dimension
        gravity_direction
        
    end
    
end

