classdef MeltMaterial < SolidificationMaterial
    
    properties ( Dependent )
        feeding_effectivity(1,1) double {...
            mustBeReal,...
            mustBeFinite,...
            mustBeGreaterThanOrEqual(feeding_effectivity,0),...
            mustBeLessThanOrEqual(feeding_effectivity,1)...
            }
        solidus_temperature_c(1,1) double {mustBeReal,mustBeFinite}
        feeding_effectivity_temperature_c(1,1) double {mustBeReal,mustBeFinite}
        liquidus_temperature_c(1,1) double {mustBeReal,mustBeFinite}
        latent_heat_j_per_kg(1,1) double {mustBeReal,mustBeFinite}
        sensible_heat_j_per_kg(1,1) double {mustBeReal,mustBeFinite}
    end
    
    methods
        function obj = MeltMaterial( file )
            obj.read( file );
        end
        
        function data = read( obj, file )
            data = obj.read@SolidificationMaterial( file );
            [ fs_t, fs_v ] = remove_nans( data.fs_t, data.fs );
            fs_in = FsProperty( fs_t, fs_v );
            obj.add( fs_in );
            obj.initial_temperature_c = obj.compute_default_initial_temperature();
            obj.fs = fs_in;
        end
        
        function ready = is_ready( obj )
            ready = obj.is_ready@SolidificationMaterial();
            ready = ready & obj.has( FsProperty.name );
        end
        
        function value = get.feeding_effectivity( obj )
            value = obj.fs.feeding_effectivity;
        end
        
        function set.feeding_effectivity( obj, value )
            obj.fs.feeding_effectivity = value;
        end
        
        function value = get.solidus_temperature_c( obj )
            value = obj.get( FsProperty.name ).solidus_temperature_c;
        end
        
        function value = get.feeding_effectivity_temperature_c( obj )
            value = obj.get( FsProperty.name ).feeding_effectivity_temperature_c;
        end
        
        function value = get.liquidus_temperature_c( obj )
            value = obj.get( FsProperty.name ).liquidus_temperature_c;
        end
        
        function value = get.latent_heat_j_per_kg( obj )
            q_solidus = obj.lookup( QProperty.name, obj.solidus_temperature_c );
            q_liquidus = obj.lookup( QProperty.name, obj.liquidus_temperature_c );
            total_heat = q_liquidus - q_solidus;
            value = total_heat - obj.sensible_heat_j_per_kg;
        end
        
        function value = get.sensible_heat_j_per_kg( obj )
            value = obj.compute_sensible_heat( ...
                obj.solidus_temperature_c, ...
                obj.liquidus_temperature_c ...
                );
        end
    end
    
    properties ( Access = private )
        fs FsProperty
    end
    
    methods ( Access = private )
        function t = compute_default_initial_temperature( obj )
            t_k = obj.liquidus_temperature_c ...
                - TemperatureDependentPropertyBase.TEMPERATURE_RANGE( 1 );
            t = ( 1.05 .* t_k ) ...
                + TemperatureDependentPropertyBase.TEMPERATURE_RANGE( 1 );
        end
        
        function value = compute_sensible_heat( obj, lower_t, upper_t )
            assert( upper_t > lower_t );
            
            d_t = upper_t - lower_t;
            lower_cp = obj.lookup( CpProperty.name, lower_t );
            upper_cp = obj.lookup( CpProperty.name, upper_t );
            value = ( lower_cp + upper_cp ) .* d_t ./ 2;
        end
    end
    
end

