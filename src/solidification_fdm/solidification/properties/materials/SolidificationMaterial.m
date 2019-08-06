classdef SolidificationMaterial < Material
    
    properties
        initial_temperature_c(1,1) double {mustBeReal,mustBeFinite} = 25
    end
    
    methods
        function data = read( obj, file )
            data = readtable( file );
            [ cp_t, cp ] = remove_nans( data.cp_t, data.cp );
            [ k_t, k ] = remove_nans( data.k_t, data.k );
            [ rho_t, rho ] = remove_nans( data.rho_t, data.rho );
            obj.add( CpProperty( cp_t, cp ) );
            obj.add( KProperty( k_t, k ) );
            obj.add( RhoProperty( rho_t, rho ) );
        end
        
        function add( obj, property )
            add@Material( obj, property );
            if property.name == CpProperty.name
                add@Material( obj, QProperty( property ) );
            end
        end
        
        function ready = is_ready( obj )
            ready = obj.has( RhoProperty.name );
            ready = ready & obj.has( CpProperty.name );
            ready = ready & obj.has( KProperty.name );
            ready = ready & obj.has( QProperty.name );
        end
    end
    
end

