function cs = replicate_color_specs( cs, n )

if ~iscell( cs )
    cs = { cs };
end
    
if numel( cs ) == 1
    cs = repmat( cs, [ n 1 ] );
end

end

