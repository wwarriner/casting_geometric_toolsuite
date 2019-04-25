classdef (Sealed) Undercuts < Process
    
    properties ( GetAccess = public, SetAccess = private )
        %% inputs
        mesh
        
        %% outputs
        array
        cc
        count
        volume
        
        volume_ratio
        
    end
    
    
    methods ( Access = public )
        
        function obj = Undercuts( varargin )
            
            obj = obj@Process( varargin{ : } );
            
        end
        
        
        function run( obj )
            
            assert( ~isempty( obj.parting_dimension ) );
            
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
            end
            assert( ~isempty( obj.mesh ) );
            
            obj.printf( ...
                'Locating undercuts for axis %d...\n', ...
                obj.parting_dimension ...
                );
            obj.paint_undercuts( obj.parting_dimension, obj.mesh.interior );
            obj.cc = bwconncomp( obj.array );
            obj.count = double( obj.cc.NumObjects );
            obj.volume = obj.mesh.to_stl_volume( sum( obj.array( : ) ) );
            obj.volume_ratio = obj.volume ./ obj.mesh.to_stl_volume( obj.mesh.volume );
            
        end
        
        
        function legacy_run( obj, mesh, parting_dimension )
            
            if nargin < 3
                parting_dimension = obj.DEFAULT_PARTING_DIMENSION;
            end
            
            obj.mesh = mesh;
            obj.parting_dimension = parting_dimension;
            obj.run();
            
        end
        
        
        function write( obj, title, common_writer )
            
            common_writer.write_array( title, obj.to_array() );
            common_writer.write_table( title, obj.to_table() );
            
        end
        
        
        function a = to_array( obj )
            
            a = obj.array;
            
        end
        
    end
    
    
    methods ( Access = public, Static )
        
        function name = NAME()
            
            name = mfilename( 'class' );
            
        end
        
        
        function orientation_dependent = is_orientation_dependent()
            
            orientation_dependent = true;
            
        end
        
        
        function gravity_direction = has_gravity_direction()
            
            gravity_direction = false;
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function names = get_table_names( ~ )
            
            names = { ...
                'count', ...
                'volume_ratio' ...
                };
            
        end
        
        
        function values = get_table_values( obj )
            
            values = { ...
                obj.count, ...
                obj.volume_ratio ...
                };
            
        end
        
    end
    
    
    properties ( Access = private )
        
        rotated_interior
        
    end
    
    
    methods ( Access = private )
        
        function paint_undercuts( obj, parting_dimension, mesh_interior )
            
            [ obj.rotated_interior, inverse ] = rotate_to_dimension( ...
                parting_dimension, ...
                mesh_interior ...
                );
            sz = size( obj.rotated_interior );
            obj.array = zeros( sz );
            
            painting = false;
            for i = 1 : sz( 1 )
                
                for k = 1 : sz( 3 )
                    
                    painting = obj.paint_forward( i, k, sz( 2 ), painting );
                    painting = obj.unpaint_reverse( i, k, sz( 2 ), painting );
                    
                end
                
            end
            
            obj.array = Undercuts.remove_spurious_undercuts( obj.array );
            obj.array = rotate_from_dimension( obj.array, inverse );
            
        end
        
        
        function painting = paint_forward( obj, i, k, col_length, painting )
            
            for j = 1 : col_length
                
                if obj.rotated_interior( i, j, k ) == 1
                    
                    painting = true;
                    
                end
                
                if painting == true && obj.rotated_interior( i, j, k ) == 0
                    
                    obj.array( i, j, k ) = 1;
                    
                end
                
            end
            
        end
        
        
        function painting = unpaint_reverse( obj, i, k, col_length, painting )
            
            for j = col_length : -1 : 1
                
                if painting == true
                    
                    if obj.rotated_interior( i, j, k ) == 0
                        
                        obj.array( i, j, k ) = 0;
                        
                    else
                        
                        painting = false;
                        
                    end
                    
                end
                
            end
            
        end
        
    end
    
    
    methods ( Access = private, Static )
        
        function core_array = remove_spurious_undercuts( core_array )
            
            core_array = remove_small_connected_regions( core_array );
            
        end
        
    end
    
end

