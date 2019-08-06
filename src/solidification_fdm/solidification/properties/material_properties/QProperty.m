classdef QProperty < TemperatureDependentPropertyBase
    
    properties ( Constant )
        name = "q"
    end
    
    methods ( Access = public )
        function obj = QProperty( varargin )
            if nargin == 1
                cp = varargin{ 1 };
                assert( isa( cp, 'CpProperty' ) );
                
                [ t, v ] = QProperty.compute( cp );
            else
                t = varargin{ 1 };
                v = varargin{ 2 };
            end
            obj = obj@TemperatureDependentPropertyBase( t, v );
            obj.cp = cp;
        end
    end
    
    properties ( Access = private )
        cp
    end
    
    methods ( Access = private, Static )
        function [ t, v ] = compute( cp )
            t = unique( [ cp.TEMPERATURE_RANGE; cp.temperatures ] );
            q_v = cp.lookup( t );
            v = cumtrapz( t, q_v );
        end
    end
    
end

