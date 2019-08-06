classdef ThermalProfileQuery < handle
    
    properties
        maximum_iterations(1,1) uint32 {mustBePositive} = 100;
        quality_target(1,1) double {mustBeReal,mustBeFinite,mustBePositive} =  1/100;
        quality_tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1e-2;
        stagnation_tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1e-2;
    end
    
    methods
        function build( obj, mesh, pp, cavity_id )
            assert( isa( mesh, 'UniformVoxelMesh' ) );
            
            assert( isa( pp, 'PhysicalProperties' ) );
            
            assert( isa( cavity_id, 'uint32' ) );
            assert( isscalar( cavity_id ) );
            assert( 0 < cavity_id );
            
            u_fn = @(id,locations)pp.lookup_initial_temperatures( id ) ...
                * ones( sum( locations ), 1 );
            u = mesh.apply_material_property_fn( u_fn );
            
            problem_in = SolidificationProblem( mesh, pp, cavity_id, u );
            
            max_dx = max( mesh.distances, [], 'all' );
            
            iterator_in = QualityBisectionIterator( problem_in );
            iterator_in.maximum_iterations = obj.maximum_iterations;
            iterator_in.quality_target = obj.quality_target;
            iterator_in.quality_tolerance = obj.quality_tolerance;
            iterator_in.stagnation_tolerance = obj.stagnation_tolerance;
            iterator_in.initial_time_step = pp.compute_initial_time_step( max_dx );
            
            times_in = SolidificationTimeResult( mesh, pp, problem_in, iterator_in );
            
            obj.mesh = mesh;
            obj.problem = problem_in;
            obj.iterator = iterator_in;
            obj.times = times_in;
        end
        
        function run( obj )
            p = obj.problem;
            looper = Looper( obj.iterator, @p.is_finished );
            looper.add_result( obj.times );
            looper.run();
        end
        
        % @get returns the distance field masked in by @mask_optional.
        % - @values is an ND array of the thermal modulus.
        % - @mask_optional is a logical array of size @get_size() where false 
        % elements are set to 0 in @values. Default is all true.
        function values = get( obj, mask_optional )
            if nargin < 2
                mask_optional = true( size( obj.times.values ) );
            end
            assert( islogical( mask_optional ) );
            assert( all( size( obj.times.values ) == size( mask_optional ) ) );
            
            values = obj.times.modulus;
            values( isnan( values ) ) = 0;
            values = obj.mesh.reshape( values );
            values( ~mask_optional ) = 0;
        end
    end
    
    properties ( Access = private )
        mesh UniformVoxelMesh
        problem SolidificationProblem
        iterator % IteratorBase
        times SolidificationTimeResult
    end
    
end

