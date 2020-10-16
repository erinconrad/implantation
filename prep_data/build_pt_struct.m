function build_pt_struct(overwrite)

locations = implant_files;
data_folder = [locations.main_folder,'data/'];
pwname = locations.pwfile;

%% Load the file with the names of patients
T = readtable([data_folder,'reimplantation patients.xlsx']);

if overwrite == 0
    % Load the pt file to see how much we've done
    if exist([data_folder,'pt.mat'],'file') ~= 0
        pt = load([data_folder,'pt.mat']);
        pt = pt.pt;
        start_pt = 1;
        for i = 1:length(pt)
            if isfield(pt(i),'filename')
                j = length(pt(i).filename);
                if ~isempty(pt(i).filename) && isfield(pt(i).filename(j),'fs') && ~isempty(pt(i).filename(j).fs)
                    start_pt = i + 1;
                end
            end
        end
    else
        start_pt = 1;
    end
else
    start_pt = 1;
end

% Loop through rows of table
for i = start_pt:size(T,1)
    
    % parse the name
    filename = T.Var1{i};
    fname = strsplit(filename,'_');
    name = fname{1};
    
    pt(i).name = name;
    
    % get if there are multiple files
    if length(fname) == 3
        dname = fname{3};
        
        % the last character is the last number
        last_num = str2num(dname(end));
        
        for d = 1:last_num
            pt(i).ieeg_names{d} = [name,'_phaseII_D0',sprintf('%d',d)];
        end
    elseif length(fname) == 2 && ~strcmp(fname{2},'phaseII')
        dname = fname{2};
        last_num = str2num(dname(end));
        
        for d = 1:last_num
            pt(i).ieeg_names{d} = [name,'_phaseII_D0',sprintf('%d',d)];
        end
    else
        pt(i).ieeg_names{1} = filename;
    end
    
    pt(i).reimplant = T.Var2(i);
    
end



%% Loop through patients and get data for each file
for i = start_pt:length(pt)
    fprintf('\nDoing %s\n',pt(i).name);
    for j = 1:length(pt(i).ieeg_names)
        pt(i).filename(j).ieeg_name = pt(i).ieeg_names{j};
        
        % Download data
        data = download_eeg(pt(i).ieeg_names{j},[],pwname,1,[]);
        
        pt(i).filename(j).chLabels = data.chLabels(:,1);
        pt(i).filename(j).fs = data.fs;
    end
    %% Save the patient structure
    save([data_folder,'pt.mat'],'pt');
end
 



end