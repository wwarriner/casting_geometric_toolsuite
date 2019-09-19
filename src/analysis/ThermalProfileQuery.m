classdef ThermalProfileQuery < handle
    
    properties
        maximum_iterations(1,1) uint32 {mustBePositive} = 100;
        quality_target(1,1) double {mustBeReal,mustBeFinite,mustBePositive} =  1/100;
        quality_tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1e-2;
        stagnation_tolerance(1,1) double {mustBeReal,mustBeFinite,mustBePositive} = 1e-2;
    end
    
    methods
        function build( obj, mesh, smp, sip, melt_id )
            assert( isa( mesh, 'MeshInterface' ) );
            
            assert( isa( smp, 'SolidificationMaterialProperties' ) );
            assert( isa( sip, 'SolidificationInterfaceProperties' ) );
            
            assert( isa( melt_id, 'uint32' ) );
            assert( isscalar( melt_id ) );
            assert( 0 < melt_id );
            
            u_fn = @(id,locations)smp.lookup_initial_temperatures( id ) ...
                * ones( sum( locations ), 1 );
            u = mesh.apply_material_property_fn( u_fn );
            
            problem_in = SolidificationProblem( mesh, smp, sip, melt_id, u );
            
            iterator_in = QualityBisectionIterator( problem_in );
            iterator_in.maximum_iterations = obj.maximum_iterations;
            iterator_in.quality_target = obj.quality_target;
            iterator_in.quality_tolerance = obj.quality_tolerance;
            iterator_in.stagnation_tolerance = obj.stagnation_tolerance;
            
			% Add optional sequential iterator, may take significant refactoring?
            % fn = @(i)0.17 .* sqrt( i );
            % iterator_in = SequentialIterator( problem_in, fn );
            
            times_in = SolidificationTimeResult( mesh, problem_in, iterator_in );
            
            obj.mesh = mesh;
            obj.problem = problem_in;
            obj.iterator = iterator_in;
            obj.times = times_in;
        end
        
        function run( obj )
            p = obj.problem;
            looper = Looper( obj.iterator, @p.is_finished );
            looper.add_result( obj.times );
            %t = tic;
            looper.run();
            %toc( t );
        end
        
        % @get_profile returns the distance field masked in by
        % @mask_optional.
        % - @values is an ND array of the thermal modulus.
        % - @mask_optional is a logical array of size @get_size() where
        % false elements are set to 0 in @values. Default is all true.
        function values = get_profile( obj, mask_optional )
            values = obj.times.modulus;
            values = obj.mesh.reshape( values );
            shape = size( values );
            
            if nargin < 2
                mask_optional = true( shape );
            end
            assert( islogical( mask_optional ) );
            assert( all( shape == size( mask_optional ) ) );
            
            values( isnan( values ) ) = 0;
            values( ~mask_optional ) = 0;
        end
        
        % @get_final_temperature returns the distance field masked in by
        % @mask_optional.
        % - @values is an ND array of the thermal modulus.
        % - @mask_optional is a logical array of size @get_size() where
        % false elements are set to 0 in @values. Default is all true.
        function values = get_final_temperature( obj, mask_optional )
            values = obj.problem.u;
            values = obj.mesh.reshape( values );
            shape = size( values );
            
            if nargin < 2
                mask_optional = true( shape );
            end
            assert( islogical( mask_optional ) );
            assert( all( shape == size( mask_optional ) ) );
            
            values( isnan( values ) ) = 0;
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

