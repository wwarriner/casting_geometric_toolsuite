function build_casting_geometric_toolsuite( out_folder )

if nargin == 0
    out_folder = fileparts( mfilename( 'fullpath' ) );
end

generate_process_implementation_includer( out_folder );

end

