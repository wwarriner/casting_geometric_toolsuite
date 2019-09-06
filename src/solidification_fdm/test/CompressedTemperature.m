classdef CompressedTemperature < ResultInterface
    
    properties
        i(1,1) double = 1
        t(:,1) double
        u(:,:) double
        err(:,1) double
        
        knots(:,:) double
        coefs1(:,:) double
        coefs2(:,:) double
    end
    
    properties ( SetAccess = private )
        values
    end
    
    methods
        function obj = CompressedTemperature( iterator, problem )
            obj.iterator = iterator;
            obj.problem = problem;
        end
        
        function update( obj )
            obj.t(obj.i) = obj.iterator.t - obj.iterator.dt;
            obj.u(obj.i,:) = obj.problem.u;
            obj.i = obj.i + 1;
        end
        
        function compress( obj, indices )
            if nargin < 2
                indices = 1 : size( obj.u, 2 );
            end
            
            tic;
            degree = 3;
            pieces = 15;
            count = size( obj.u, 2 );
            obj.err = zeros( 1, count );
            obj.knots = zeros( pieces + 1, count );
            obj.coefs1 = zeros( pieces + 1, count );
            obj.coefs2 = zeros( pieces + 1, count );
            for k = indices( : ).'
                if ~obj.problem.primary_melt( k )
                    continue;
                end
                spg = SplineGenerator( degree, obj.t, obj.u(:,k) );
                obj.err( k ) = spg.generate( pieces );
                obj.knots(:,k) = spg.sp.knots;
                obj.coefs1(:,k) = spg.sp.coef(:,1);
                obj.coefs2(:,k) = spg.sp.coef(:,2);
            end
            toc;
        end
        
        function temp = evaluate( obj, time )
            is_melt = obj.problem.primary_melt;
            temp = quickeval( ...
                time, ...
                obj.knots( :, is_melt ), ...
                obj.coefs1( :, is_melt ), ...
                obj.coefs2( :, is_melt ) ...
                );
        end
    end
    
    properties ( Access = private )
        iterator %IteratorBase
        problem SolidificationProblem
    end
    
end