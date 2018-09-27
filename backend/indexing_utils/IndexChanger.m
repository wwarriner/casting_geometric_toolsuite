classdef (Sealed) IndexChanger < handle
    %INDEXCHANGER Changes indices from array to padded array
    
    properties ( Access = private )
        
        dims
        old
        new
        pad
        
    end
    
    
    methods ( Access = public )
        
        function obj = IndexChanger( old_size, new_size, front_padding )
            
            assert( isnumeric( old_size ) );
            assert( isvector( old_size ) );
            
            assert( isnumeric( new_size ) );
            assert( isvector( new_size ) );
            
            assert( isnumeric( front_padding ) );
            assert( isvector( front_padding ) );
            
            assert( numel( old_size ) == numel( new_size ) );
            assert( numel( old_size ) == numel( front_padding ) );
            
            obj.dims = numel( old_size );
            obj.old = old_size;
            obj.new = new_size;
            obj.pad = front_padding;
            
        end
        
        
        function new_indices = change( obj, old_indices )

            subs = ind2sub_vec( obj.old, old_indices ) + obj.pad;
            new_indices = sub2ind_vec( obj.new, subs );
            
        end
        
        
        function old_indices = revert( obj, new_indices )

            subs = ind2sub_vec( obj.new, new_indices );
            subs = subs - obj.pad;
            old_indices = sub2ind_vec( obj.old, subs );
            
        end
        
        function new_subs = oldind2newsub( obj, old_indices )
            
            new_indices = obj.change( old_indices );
            new_subs = ind2sub_vec( obj.new, new_indices );
            
        end
        
    end
    
    
end

