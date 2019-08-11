function t = map2table( m )

v = m.values();
t = table( v{ : }, 'variablenames', m.keys() );

end

