classdef ( Sealed ) MeshEnvelope < ProcessHelper
    
    properties ( GetAccess = public, SetAccess = private )
        
        min_point;
        max_point;
        lengths;
        volume;
        
    end
    
    methods ( Access = public )
        
        % standard matlab fv struct
        % -OR-
        % min_point, max_point as two vectors of length 3
        function obj = MeshEnvelope( varargin )
            
            if nargin == 1
                
                fv = varargin{ 1 };
                min_point = min( fv.vertices, [], 1 );
                max_point = max( fv.vertices, [], 1 );
                
            elseif nargin == 2
                
                min_point = varargin{ 1 };
                max_point = varargin{ 2 };
                
            else
                
                error( 'Incorrect number of arguments creating MeshEnvelope' );
                
            end
            
            assert( isnumeric( min_point ) );
            assert( isvector( min_point ) );
            assert( numel( min_point ) == 3);
            
            assert( isnumeric( max_point ) );
            assert( isvector( max_point ) );
            assert( numel( max_point ) == 3);
            
            obj.min_point = min_point;
            obj.max_point = max_point;
            obj.recompute();
            
        end
        
        
        function extrema = get_extrema( obj, dimension )
            
            extrema = [ ...
                obj.min_point( dimension ) ...
                obj.max_point( dimension ) ...
                ];
            
        end
        
        
        function add_uniform_padding( obj, padding )
            
            obj.min_point = obj.min_point - padding;
            obj.max_point = obj.max_point + padding;
            obj.recompute();
            
        end
        
        
        function add_padding( obj, pre_padding, post_padding )
            
            obj.min_point = obj.min_point - pre_padding;
            obj.max_point = obj.max_point + post_padding;
            obj.recompute();
            
        end
        
        
        function tr = to_table_row( obj )
            
            tr = [ ...
                num2cell( obj.min_point ) ...
                num2cell( obj.max_point ) ...
                num2cell( obj.lengths ) ...
                { obj.volume } ...
                ];
            assert( numel( tr ) == obj.get_table_row_length() );
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function trn = get_table_row_names()
            
            trn = [ ...
                append_dimension_suffix( 'min' ) ...
                append_dimension_suffix( 'max' ) ...
                append_dimension_suffix( 'lengths' ) ...
                { 'volume' } ...
                ];
            trn = affix_table_names( trn, 'mesh_envelope', '' );
            
        end
        
    end
    
    
    methods ( Access = private )
        
        function recompute( obj )
            
            obj.min_point = min( obj.min_point, obj.max_point );
            obj.max_point = max( obj.min_point, obj.max_point );
            obj.lengths = obj.max_point - obj.min_point;
            obj.volume = prod( obj.lengths );
            
        end
        
    end
    
end

