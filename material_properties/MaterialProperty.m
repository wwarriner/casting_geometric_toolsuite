classdef MaterialProperty < handle & matlab.mixin.Heterogeneous
    
    properties ( GetAccess = public, SetAccess = private )
        
        temperatures
        values
        
    end
    
    
    methods ( Access = public, Abstract )
        
        nd_material_property = nondimensionalize( obj, v_factor, t_range );
        
    end
    
    
    methods ( Access = public, Static, Abstract )
        
        fn = get_extreme_fn( obj );
        
    end
    
    
    methods ( Access = public )
        
        function extreme = get_extreme( obj )
            
            fn = obj.get_extreme_fn();
            extreme = fn( obj.values );
            
        end
        
        
        function [ t, v ] = nondimensionalize_impl( obj, v_factor, t_range )
            
            assert( numel( t_range ) == 2 );
            t_range = sort( t_range );
            t = scale_temperatures( obj.temperatures, t_range );
            v = obj.values ./ v_factor;
            
        end
        
        
        function values = lookup_values( obj, temperatures )
            
            if numel( obj.temperatures ) == 1
                values = obj.values .* ones( size( temperatures ) );
            else
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
        
        
        function temperature = lookup_temperatures( obj, value )
            
            if numel( obj.temperatures ) == 1
                temperature = obj.temperatures .* ones( size( value ) );
            else
                temperature = interp1( ...
                    obj.values, ...
                    obj.temperatures, ...
                    value, ...
                    'linear', ...
                    'extrap' ...
                    );
            end
            
        end
        
    end
    
    
    properties ( Access = protected, Constant )
        
        DEFAULT_TEMPERATURE = realmax();
        
    end
    
    
    methods ( Access = protected )
        
        % preconditions
        %  - both double vectors with non-negative finite values
        %  - temperatures strictly increasing from 1 to end
        %  - both have same length
        function obj = MaterialProperty( temperatures, values )
            
            if ~isempty( temperatures )
                assert( isvector( temperatures ) );
                assert( isa( temperatures, 'double' ) );
                assert( all( isfinite( temperatures ) ) );
                assert( all( 0 <= temperatures ) );
                assert( all( 0 < diff( temperatures ) ) );
            end
            
            if ~isempty( values )
                assert( isvector( values ) );
                assert( isa( values, 'double' ) );
                assert( all( isfinite( values ) ) );
                assert( all( 0 <= values ) );
            end
            
            assert( numel( temperatures ) == numel( values ) );
            
            obj.temperatures = temperatures( : );
            obj.values = values( : );
            
        end
        
    end
    
    
    methods ( Access = protected, Static, Sealed )
        
        function default = getDefaultScalarElement()
            
            default = NullProperty();
            
        end
        
    end
    
end

