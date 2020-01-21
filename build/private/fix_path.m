function path_restorer = fix_path()

old_path = path();
path_restorer = onCleanup(@()path(old_path));
restoredefaultpath();

end