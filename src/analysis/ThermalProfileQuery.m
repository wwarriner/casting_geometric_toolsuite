classdef ThermalProfileQuery < handle
    
    properties
        maximum_iterations(1,1) uint32 {mustBePositive} = 100;
        quality_tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 0.2;
        stagnation_tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1e-2;
    end
    
    methods
        function obj = ThermalProfileQuery( mesh, pp, cavity_id )
            assert( isa( mesh, 'UniformVoxelMesh' ) );
            
            assert( isa( pp, 'PhysicalProperties' ) );
            
            assert( isa( cavity_id, 'uint32' ) );
            assert( isscalar( cavity_id ) );
            assert( 0 < cavity_id );
            
            u_fn = @(id,locations)pp.lookup_initial_temperatures( id ) ...
                * ones( sum( locations ), 1 );
            u = mesh.apply_material_property_fn( u_fn );
            
            problem = SolidificationProblem( mesh, pp, cavity_id, u );
            
            iterator = QualityBisectionIterator( problem );
            iterator.maximum_iterations = obj.maximum_iterations;
            iterator.quality_tolerance = obj.quality_tolerance;
            iterator.stagnation_tolerance = obj.stagnation_tolerance;
            iterator.initial_time_step = pp.compute_initial_time_step();
            
            times = SolidificationTimeResult( mesh, pp, problem, iterator );
            
            looper = Looper( iterator, @problem.is_finished );
            looper.add_result( times );
            looper.run();
            
            modulus = times.modulus;
            modulus( isnan( modulus ) ) = 0;
            obj.values = mesh.reshape( modulus );
        end
        
        % @get returns the distance field masked in by @mask_optional.
        % - @values is an ND array of the thermal modulus.
        % - @mask_optional is a logical array of size @get_size() where false 
        % elements are set to 0 in @values. Default is all true.
        function values = get( obj, mask_optional )
            if nargin < 2
                mask_optional = true( size( obj.values ) );
            end
            assert( islogical( mask_optional ) );
            assert( all( size( obj.values ) == size( mask_optional ) ) );
            
            values = obj.values;
            values( ~mask_optional ) = 0;
        end
    end
    
    properties ( Access = private )
        values(:,:,:) double {mustBeReal,mustBeFinite}
    end
    
end

