classdef Printer < handle
    
    methods ( Access = public )
        
        function printf( obj, varargin )
            
            if obj.get_verbosity()
                printer_fn = obj.get_printer();
                if ~isempty( printer_fn )
                    printer_fn( varargin{ : } );
                end
            end
            
        end
    
    end
    
    
    methods ( Access = public, Static )
        
        function printer_fn = get_printer()
            
            printer_fn = utils.Printer.printer_fn();
            
        end
        
        
        function set_printer( printer_fn )
            
            utils.Printer.printer_fn( printer_fn );
            
        end
        
        
        function verbosity = get_verbosity()
            
            verbosity = utils.Printer.verbosity();
            
        end
        
        function set_verbosity( verbosity )
            
            utils.Printer.verbosity( verbosity );
            
        end
        
        function turn_print_off()
            
            utils.Printer.set_verbosity( false );
            
        end
        
        function turn_print_on()
            
            utils.Printer.set_verbosity( true );
            
        end
        
    end
    
    
    methods ( Access = protected )
        
        function obj = Printer(); end
        
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
        
        
        function get_printer_fn = printer_fn( set_printer_fn )
            
            persistent printer_fn;
            
            if nargin > 0
                printer_fn = set_printer_fn;
            end
            get_printer_fn = printer_fn;
            
        end
        
    end
    
end

