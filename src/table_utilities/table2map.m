function m = table2map( t )

m = containers.Map( ...
    'keytype', 'char', ...
    'valuetype', 'any' ...
    );
keys = t.Properties.VariableNames;
for i = 1 : numel( keys )
    m( keys{ i } ) = t{ :, i };
end

end

