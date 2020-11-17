function pt = get_sz_times

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/'];
results_folder = [locations.main_folder,'results/'];
out_folder = [results_folder,'spikes/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));
metadata_folder = [data_folder,'metadata/'];
pt_folder = [data_folder,'data_files/'];

%% Load pt file
pt = load([pt_folder,'pt_w_elecs.mat']);
pt = pt.pt;

%% Get metadata info
metadata_file = [metadata_folder,'ieeg_event_times.xlsx'];
[status, sheetNames] = xlsfinfo(metadata_file);
nsheets = length(sheetNames);

%% Loop through sheet names and fill in sz info for appropriate patients
for s = 1:nsheets
    curr_sheet_name = sheetNames{s};
    
    % Load the sheet
    T = readtable(metadata_file,'Sheet',s,'ReadVariableNames',0);
    
    if isempty(T), continue; end
    
    % Convert the table to a numerical array
    times = T.Var1;
    files = T.Var2;
    
    % Convert the file names to numbers
    file_nums = cellfun(@(x) str2num(x(end)),files); 
    
    sz_times = [times,file_nums];
    
    % Loop through pt struct and find corresponding patient
    found_it = 0;
    for p = 1:length(pt)
        pt_name = pt(p).name;
        
        if strcmp(pt_name,curr_sheet_name)

            % Add sz times
            pt(p).sz_times = sz_times;
            
            % Break out of the pt loop
            found_it = 1;
            break
            
        end
    end
    
    if found_it == 0
        fprintf('\nWarning, did not find pt for %s\n',curr_sheet_name);
    end
    
end

%% Save pt file
save([pt_folder,'pt_w_elecs.mat'],'pt')

end
