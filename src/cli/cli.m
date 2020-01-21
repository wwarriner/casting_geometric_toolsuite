function out = cli( settings_json_file )

out = 0;

try
    settings = Settings( settings_json_file );
catch e
    out = 1;
    disp( getReport( e, "extended" ) );
    return;
end

try
    pm = ProcessManager( settings );
catch e
    out = 2;
    disp( getReport( e, "extended" ) );
    return;
end

try
    pm.run();
catch e
    out = 3;
    disp( getReport( e, "extended" ) );
    return;
end

try
    pm.write_all();
catch e
    out = 4;
    disp( getReport( e, "extended" ) );
    return;
end

end
