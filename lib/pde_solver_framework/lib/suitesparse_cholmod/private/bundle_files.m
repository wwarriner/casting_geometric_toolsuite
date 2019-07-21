function bundle_files( target )
%% SETUP
DEFAULT_OUT_NAME = 'bundle.zip';
[ this_folder, this_name ] = fileparts( mfilename( 'fullpath' ) );

%% ARGS
if nargin < 1
    target = fullfile( this_folder, DEFAULT_OUT_NAME );
end

%% GET MEX FILE LIST
mex_files = dir( fullfile( this_folder, '**', '*.mex*' ) );

%% GET M FILE LIST
m_files = dir( fullfile( this_folder, '**', '*.m' ) );
matches = false( 1, numel( m_files ) );
ew_folder_ptn = { [ filesep 'test' ] };
for i = 1 : numel( ew_folder_ptn )
    
    matches = matches | endsWith( ...
        { m_files.folder }, ...
        ew_folder_ptn{ i }, ...
        'ignorecase', true ...
        );
    
end
ew_file_ptn = { ...
    [ this_name '.m' ], 'testmex.m' '_test.m' ...
    '_demo.m' '_install.m' '_make.m', 'Contents.m', ...
    'lperf.m' ...
    };
for i = 1 : numel( ew_file_ptn )
    
    matches = matches | endsWith( ...
        { m_files.name }, ...
        ew_file_ptn{ i }, ...
        'ignorecase', true ...
        );
    
end
m_files( matches, : ) = [];

%% GET DOCUMENTATION FILE LIST
pdf_files = dir( fullfile( this_folder, '**', 'Doc', '*.pdf' ) );
sub_licenses = dir( fullfile( this_folder, '**', 'Doc', '*.txt' ) );
lic_names = { sub_licenses.name };
lic_folders = { sub_licenses.folder };
lic_folders = cellfun( @(x)strsplit( x, filesep ), lic_folders, 'uniformoutput', false );
lic_folders = cellfun( @(x)x{ end - 1 }, lic_folders, 'uniformoutput', false );
lic_names = cellfun( @(x, y)[ x '_' y ], lic_folders, lic_names, 'uniformoutput', false );
lic_dir = fullfile( this_folder, 'lic' );
if isfolder( lic_dir )
    rmdir( lic_dir, 's' );
end
mkdir( lic_dir );
for i = 1 : numel( sub_licenses )
    
    copyfile( ...
        fullfile( sub_licenses( i ).folder, sub_licenses( i ).name ), ...
        fullfile( lic_dir, lic_names{ i } ) ...
        );
    
end
sub_licenses = dir( fullfile( lic_dir, '*.txt' ) );

other_docs = dir( fullfile( this_folder, '*.txt' ) );
other_docs = [ other_docs; dir( fullfile( this_folder, '*.md' ) ) ];

doc_files = [ pdf_files; sub_licenses; other_docs ];

%% MERGE LISTS AND REMOVE DUPLICATES
files = [ mex_files; m_files ];
names = { files.name };
[ ~, i ] = unique( names );
inds = setdiff( 1 : numel( names ), i );
duplicates = false( 1, numel( names ) );
duplicates( inds ) = 1;
files( duplicates ) = [];

files = [ files; doc_files ];
fullnames = cellfun( @fullfile, { files.folder }, { files.name }, 'uniformoutput', false );
if isfolder( target )
    for i = 1 : numel( fullnames )
        copyfile( fullnames{ i }, target );
    end
elseif isfile( target )
    zip( target, fullnames );
end

end


