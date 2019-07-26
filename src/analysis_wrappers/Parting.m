classdef (Sealed) Parting < Process
    
    properties ( SetAccess = private, Dependent )
        count(1,1) uint64
        area(1,1) double
        length(1,1) double
        draw(1,1) double
        perimeter_labels(:,:,:) uint64
        jog_free_labels(:,:,:) uint64
        line_labels(:,:,:) uint64
    end
    
    properties ( Constant )
        PERIMETER uint64 = 1
        JOG_FREE uint64 = 2
        LINE uint64 = 3
    end
    
    methods
        function obj = Parting( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function run( obj )
            if ~isempty( obj.results )
                mesh_key = ProcessKey( Mesh.NAME );
                obj.mesh = obj.results.get( mesh_key );
            end
            assert( ~isempty( obj.mesh ) );
            
            obj.printf( ...
                'Locating parting perimeter...\n', ...
                obj.parting_dimension ...
                );
            obj.perimeter = PartingPerimeterQuery( obj.mesh.interior );
        end
        
        function legacy_run( obj, mesh )
            obj.mesh = mesh;
            obj.run();
        end
        
        function write( obj, common_writer )
            common_writer.write_array( obj.NAME, obj.to_array() );
            common_writer.write_table( obj.NAME, obj.to_table() );
        end
        
        function a = to_array( obj )
            a = double( obj.perimeter_labels );
            a( a > 0 ) = obj.PERIMETER;
            jf = obj.jog_free_labels;
            a( jf ) = obj.JOG_FREE;
            pl = obj.line_labels;
            a( pl ) = obj.LINE;
        end
        
        function value = get.count( obj )
            value = obj.perimeter.count;
        end
        
        function value = get.area( obj )
            value = obj.mesh.to_stl_area( obj.perimeter.projected.area );
        end
        
        function value = get.length( obj )
            value = obj.mesh.to_stl_units( obj.perimeter.projected.area );
        end
        
        function value = get.draw( obj )
            value = obj.mesh.to_stl_units( obj.perimeter.line.draw );
        end
        
        function value = get.perimeter_labels( obj )
            value = obj.perimeter.label_array;
        end
        
        function value = get.jog_free_labels( obj )
            value = obj.perimeter.jog_free.label_array;
        end
        
        function value = get.line_labels( obj )
            value = obj.perimeter.line.label_array;
        end
    end
    
    methods ( Access = public, Static )
        function name = NAME()
            name = mfilename( 'class' );
        end
    end
    
    methods ( Access = protected )
        function names = get_table_names( ~ )
            names = { ...
                'count' ...
                'area' ...
                'length' ...
                'draw' ...
                };
        end
        
        function values = get_table_values( obj )
            values = { ...
                obj.draw ...
                obj.area ...
                obj.length ...
                obj.draw ...
                }; % TODO
        end
    end
    
    properties ( Access = private )
        mesh(1,1) Mesh
        perimeter(1,1) PartingPerimeterQuery
    end
    
end

