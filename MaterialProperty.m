classdef MaterialProperty
    
    properties ( GetAccess = public, SetAccess = private )
        
        temperatures
        values
        
    end
    
    methods
        
        function obj = MaterialProperty( varargin )
            
            if nargin == 0
                temperatures = [];
                values = [];
            elseif nargin == 1
                temperatures = 0;
                values = varargin{ 1 };
            elseif nargin == 2
                temperatures = varargin{ 1 };
                values = varargin{ 2 };
            else
                assert( false );
            end
            
            obj.temperatures = temperatures;
            obj.values = values;
            
        end
        
        
        function mp = downscale( obj, v_factor, t_factor, t_offset )
            
            if nargin < 3
                t_factor = 1;
            end
            if nargin < 4
                t_offset = 0;
            end
            mp = MaterialProperty( ...
                ( obj.temperatures - t_offset ) ./ ( t_factor - t_offset ), ...
                obj.values ./ v_factor ...
                );
            
        end
        
        
        function value = lookup( obj, temperature )
            
            if numel( obj.temperatures ) == 1
                value = obj.values .* ones( size( temperature ) );
            else
                value = interp1( obj.temperatures, obj.values, temperature, 'linear', 'extrap' );
                [ t_max, v_max_ind ] = max( obj.temperatures );
                max_ind = t_max < temperature;
                value( max_ind ) = obj.values( v_max_ind );
                [ t_min, v_min_ind ] = min( obj.temperatures );
                min_ind = temperature < t_min;
                value( min_ind ) = obj.values( v_min_ind );
            end
            
        end
        
        
        function temperature = reverse_lookup( obj, value )
            
            if numel( obj.temperatures ) == 1
                temperature = obj.temperatures .* ones( size( value ) );
            else
                temperature = interp1( obj.values, obj.temperatures, value, 'linear', 'extrap' );
            end
            
        end
        
    end
end

