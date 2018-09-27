function appended_chars = append( lines, prefix, postfix )
% lines is cell array of character vector

appended_chars = lines;
for i = 1 : numel( lines )
    
    appended_chars{ i } = sprintf( '%s%s%s', prefix, appended_chars{ i }, postfix );
    
end


end

