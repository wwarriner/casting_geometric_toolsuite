classdef TemperatureDependentPropertyBase < PropertyInterface
    
    properties ( SetAccess = protected )
        temperatures(:,1) double {mustBeReal,mustBeFinite}
        values(:,1) double {mustBeReal,mustBeFinite}
    end
    
    properties ( Constant )
        TEMPERATURE_RANGE = [ -273.15; 5000 ];
    end
    
    methods
        % @t is an array of temperatures.
        % @v is an array of values the same size as @t.
        % Note that behavior is guaranteed only when all elements of @t fall in
        % @TEMPERATURE_RANGE. Checking is not performed for performance reasons.
        function v = lookup( obj, t )
            v = interp1( ...
                obj.temperatures, ...
                obj.values, ...
                t, ...
                'linear', ...
                'extrap' ...
                );
        end
        
        % @fn is a function taking a vector of values and returning a scalar
        function v = reduce( obj, fn )
            v = fn( obj.values );
        end
    end
    
    methods ( Access = protected )
        function obj = TemperatureDependentPropertyBase( varargin )
            if nargin == 1
                temperatures = TemperatureDependentPropertyBase.TEMPERATURE_RANGE;
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
            assert( obj.TEMPERATURE_RANGE( 1 ) <= temperatures( 1 ) );
            assert( temperatures( end ) <= obj.TEMPERATURE_RANGE( end ) );
            
            assert( isa( values, 'double' ) );
            assert( isvector( values ) );
            assert( all( isfinite( values ) ) );
            assert( all( 0 <= values ) );
            assert( numel( values ) == numel( temperatures ) );
            
            obj.temperatures = temperatures;
            obj.values = values;
            
            obj.t_max = max( temperatures, [], 'all' );
            obj.t_min = min( temperatures, [], 'all' );
        end
    end
    
    properties ( Access = private )
        t_max(1,1) double {mustBeReal,mustBeFinite}
        t_min(1,1) double {mustBeReal,mustBeFinite}
    end
    
end

