classdef MoldMaterial < SolidificationMaterial
    
    methods ( Access = public )
        function obj = MoldMaterial( file )
            obj.read( file );
        end
    end
    
end

