classdef ThickSectionQuery < handle
    
    properties ( SetAccess = private )
        thick_threshold(1,1) double
    end
    
    properties ( SetAccess = private, Dependent )
        count(1,1) double
        label_array(:,:,:) uint32
    end
    
    methods
        % Inputs:
        % - @edt is a real, positive double array representing the edt profile 
        % of some logical image (as from bwdist) and should have values 
        % everywhere in @mask. Values outside the mask are ignored. Values must 
        % be in voxel units.
        % - @mask is a logical array where only true values are considered
        % for computation.
        % - @strategy_fn is a scalar function handle with signature out = @(in)
        % where @in is a real, finite, double vector from @edt, and @out is a
        % real, finite, scalar double representing the thick wall threshold.
        % - @threshold is a real, finite, positive scalar double representing
        % the thickness threshold in voxel units.
        % - @sweep_coefficient (optional) is a real, finite, positive
        % scalar double which determines how aggressively to sweep. Lower
        % values tend to undersegment, and higher values oversegment.
        function obj = ThickSectionQuery( edt, mask, strategy_fn, threshold, sweep_coefficient )
            if nargin == 0
                return;
            end
            
            if nargin < 5
                sweep_coefficient = 2; % seems to work well
            end
            
            assert( isa( edt, 'double' ) );
            assert( ndims( edt ) == 3 );
            assert( isreal( edt ) );
            assert( all( isfinite( edt ), 'all' ) );
            
            assert( islogical( mask ) );
            assert( ndims( mask ) == 3 );
            assert( all( size( edt ) == size( mask ) ) );
            
            assert( isa( strategy_fn, 'function_handle' ) );
            assert( isscalar( strategy_fn ) );
            
            assert( isa( threshold, 'double' ) );
            assert( isscalar( threshold ) );
            assert( isreal( threshold ) );
            assert( isfinite( threshold ) );
            
            assert( isa( sweep_coefficient, 'double' ) );
            assert( isscalar( sweep_coefficient ) );
            assert( isreal( sweep_coefficient ) );
            assert( isfinite( sweep_coefficient ) );
            
            skeleton = bwskel( mask );
            % possible adjustment of data to remove those less than thin
            % threshold
            data = edt( skeleton );
            data = data( data > threshold );
            thick_threshold = strategy_fn( data );
            thin_query = ThinSectionQuery( edt, mask, thick_threshold, sweep_coefficient );
            thick_wall = ( thin_query.label_array <= 0 ) & mask;
            sweep_distance = sweep_coefficient .* thick_threshold;
            sweep_distance = max( sweep_distance, 1 );
            thick_wall = distance_sweep( mask, thick_wall, sweep_distance );
            obj.cc = bwconncomp( thick_wall );
            obj.thick_threshold = thick_threshold;
        end
        
        function count = get.count( obj )
            count = obj.cc.NumObjects;
        end
        
        function value = get.label_array( obj )
            value = uint32( labelmatrix( obj.cc ) );
        end
    end
    
    properties ( Access = private )
        cc(1,1) struct
    end
    
end

