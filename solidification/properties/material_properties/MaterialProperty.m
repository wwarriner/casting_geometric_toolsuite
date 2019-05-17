classdef MaterialProperty < handle
    
    properties ( GetAccess = public, SetAccess = protected )
        
        temperatures
        values
        
    end
    
    
    methods ( Access = public )
        
        function values = lookup_values( obj, temperatures )
            
            values = interp1( ...
                obj.temperatures, ...
                obj.values, ...
                temperatures, ...
                'linear', ...
                'extrap' ...
                );

            % clip above max temperature
            [ t_max, v_max_ind ] = max( obj.temperatures );
            max_ind = t_max < temperatures;
            values( max_ind ) = obj.values( v_max_ind );

            % clip below min temperature
            [ t_min, v_min_ind ] = min( obj.temperatures );
            min_ind = temperatures < t_min;
            values( min_ind ) = obj.values( v_min_ind );
            
        end
        
    end
    
    
    properties ( Access = protected, Constant )
        
        DEFAULT_TEMPERATURES = [ -273.15 5000 ];
        
    end
    
    
    methods ( Access = protected )
        
        % preconditions
        %  - both double vectors with non-negative finite values
        %  - temperatures strictly increasing from 1 to end
        %  - both have same length
        function obj = MaterialProperty( varargin )
            
            if nargin == 1
                temperatures = MaterialProperty.DEFAULT_TEMPERATURES;
                values = varargin{ 1 };
                assert( isscalar( values ) );
                values = values .* ones( size( temperatures ) );
            elseif nargin == 2
                temperatures = varargin{ 1 };
                values = varargin{ 2 };
            else
                assert( false );
            end
            
            assert( isa( temperatures, 'double' ) );
            assert( isvector( temperatures ) );
            assert( all( isfinite( temperatures ) ) );
            assert( all( 0 < diff( temperatures ) ) );
            
            assert( isvector( values ) );
            assert( isa( values, 'double' ) );
            assert( all( isfinite( values ) ) );
            assert( all( 0 <= values ) );
            
            assert( numel( temperatures ) == numel( values ) );
            
            obj.temperatures = temperatures( : );
            obj.values = values( : );
            
        end
        
    end
    
end

