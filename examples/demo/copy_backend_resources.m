function copy_backend_resources( frontend_res_path )

if ~isfolder( frontend_res_path )
    mkdir( frontend_res_path );
end

end

