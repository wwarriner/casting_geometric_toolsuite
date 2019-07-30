classdef Print < handle
    
    methods ( Access = public, Static )
        
        function verbosity = get_verbosity()
            
            verbosity = Print.verbosity();
            
        end
        
        function set_verbosity( verbosity )
            
            Print.verbosity( verbosity );
            
        end
        
        function turn_print_off()
            
            Print.set_verbosity( false );
            
        end
        
        function turn_print_on()
            
            Print.set_verbosity( true );
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function printf( obj, varargin )
            
            if obj.get_verbosity()
                fprintf( 1, varargin{ : } );
            end
            
        end
        
    end
    
    
    methods ( Access = protected, Static, Sealed )
        
        function get_verbose = verbosity( set_verbose )
            
            persistent is_verbose;
            if isempty( is_verbose )
                is_verbose = true;
            end
            
            if nargin > 0
                is_verbose = set_verbose;
            end
            get_verbose = is_verbose;
            
        end
        
    end
    
end

