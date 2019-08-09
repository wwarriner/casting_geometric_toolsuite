classdef (Sealed) Parting < Process
    % @Parting encapsulates the behavior and data of a parting line related
    % features. Finds the projected area, projected parting line length, tooling
    % draw, any jog-free perimeters, and flattest parting line.
    % Dependencies:
    % - @Mesh
    
    properties ( SetAccess = private, Dependent )
        count(1,1) double
        area(1,1) double
        length(1,1) double
        draw(1,1) double
        perimeter_labels(:,:,:) uint32
        jog_free_labels(:,:,:) uint32
        line_labels(:,:,:) uint32
    end
    
    properties ( Constant )
        PERIMETER uint32 = 1
        JOG_FREE uint32 = 2
        LINE uint32 = 3
    end
    
    methods
        function obj = Parting( varargin )
            obj = obj@Process( varargin{ : } );
        end
        
        function legacy_run( obj, mesh )
            obj.mesh = mesh;
            obj.run();
        end
        
        function write( obj, common_writer )
            common_writer.write_array( obj.NAME, obj.to_array(), obj.mesh.spacing, obj.mesh.origin );
            common_writer.write_table( obj.NAME, obj.to_table() );
        end
        
        function value = to_array( obj )
            value = double( obj.perimeter_labels );
            value( value > 0 ) = obj.PERIMETER;
            jf = obj.jog_free_labels;
            value( jf > 0 ) = obj.JOG_FREE;
            pl = obj.line_labels;
            value( pl > 0 ) = obj.LINE;
        end
        
        function value = get.count( obj )
            value = obj.perimeter.count;
        end
        
        function value = get.area( obj )
            value = obj.mesh.to_casting_area( obj.perimeter.projected.area );
        end
        
        function value = get.length( obj )
            value = obj.mesh.to_casting_length( obj.perimeter.projected.length );
        end
        
        function value = get.draw( obj )
            value = obj.mesh.to_casting_length( obj.perimeter.line.draw );
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
            name = string( mfilename( 'class' ) );
        end
    end
    
    methods ( Access = protected )
        function update_dependencies( obj )
            mesh_key = ProcessKey( Mesh.NAME );
            obj.mesh = obj.results.get( mesh_key );
            
            assert( ~isempty( obj.mesh ) );
        end
        
        function check_settings( ~ )
            % no settings need checking
        end
        
        function run_impl( obj )
            obj.prepare_parting_perimeter();
        end
        
        function value = to_table_impl( obj )
            value = list2table( ...
                { 'count' 'area' 'length' 'draw' }, ...
                { obj.count obj.area obj.length obj.draw } ...
                );
        end
    end
    
    properties ( Access = private )
        mesh Mesh
        perimeter PartingPerimeterQuery
    end
    
    methods ( Access = private )
        function prepare_parting_perimeter( obj )
            obj.printf( "Locating parting perimeter...\n" );
            obj.perimeter = PartingPerimeterQuery( obj.mesh.interior );
        end
    end
    
end

