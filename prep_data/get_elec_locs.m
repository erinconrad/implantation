function get_elec_locs

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/'];
elec_folder = [data_folder,'elec_locs/'];
results_folder = [locations.main_folder,'results/'];
out_folder = [results_folder,'spikes/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));

%% Load pt file
pt = load([data_folder,'pt.mat']);
pt = pt.pt;

np = length(pt);

%% Get electrode folder listings
listing = dir(elec_folder);

for p = 1:np
    clear locs
    
    % Check if there is master electrode info
    if ~isstruct(pt(p).master_elecs), continue; end
    elec_labels_ordered = pt(p).master_elecs.master_labels;
       
    name = pt(p).name;
    fprintf('\n\n\nDoing %s\n',name);
      
    % Check for file
    if exist([elec_folder,name,'/electrodenames_coordinates_native_and_T1.csv'],'file') == 0
        fprintf('\nCannot find electrode labels for %s, skipping...\n',name);
        continue
    end
    
    % LOad the file with native coordinates and anatomic locations
    T = readtable([elec_folder,name,'/electrodenames_coordinates_native_and_T1.csv']);
        
    % Loop through the table, find the corresponding electrode in the
    % master electrode substructure, and that will determine the electrode index.
    
    for t = 1:size(T,1)
        row = T(t,:);
        found_it = 0;
        row_label = row.Var1{1};
        for m = 1:length(elec_labels_ordered)
            curr_label = elec_labels_ordered{m};
            if ~strcmp(row_label,curr_label), continue; end
            
            found_it = 1;
            
            % When I find corresponding label, add location data to
            % structure
            locs(m) = add_loc_data(row,curr_label);

        end
        
        %% Do some exception handling for electrode labels close to the name
        if found_it == 0

            % Try adding an L or an R in front of the name            
            names_to_try{1} = ['L',row_label];
            names_to_try{2} = ['R',row_label];
            
            % pad the number with a leading zero
            num_ind = regexp(row_label,'\d*');
            num = str2num(row_label(num_ind:end));
            letters = row_label(1:num_ind-1);
            if num < 10
                new_label = [letters,'0',row_label(num_ind:end)];
            end
            names_to_try{3} = new_label;
                
            
            for m = 1:length(elec_labels_ordered)
                curr_label = elec_labels_ordered{m};
                for n = 1:length(names_to_try)
                    try_name = names_to_try{n};
                    if strcmp(try_name,curr_label)

                        fprintf('\nWarning, found approximate match between %s and %s for %s\n',...
                            row_label,curr_label,name);

                        found_it = 1;
                        locs(m) = add_loc_data(row,curr_label);
                        break % don't try the other ones

                    end
                end
            end
            
        end
        
        if found_it == 0
            fprintf('\nDid not find corresponding electrode for %s %s\n',name,row_label); 
            str = input('\nContinue? (y or n)\n','s');
            if strcmp(str,'y') || strcmp(str,'Y')
                continue;
            else
                error('Fix it!');
            end
        end
    end
    pt(p).master_elecs.locs = locs;
    
    %% Double check that names in locs are the same as the names in master elec labels
    loc_names = {};
    for l = 1:length(pt(p).master_elecs.locs)
        loc_names = [loc_names;pt(p).master_elecs.locs(l).ieeg_name];
    end
    A = setdiff(loc_names,pt(p).master_elecs.master_labels);
    fprintf('\nOther labels in elec file not in ieeg:\n');
    A
    B = setdiff(pt(p).master_elecs.master_labels,loc_names);
    fprintf('\nOther labels in ieeg not in elec file:\n');
    B
    missing_elecs.only_elec_file = A;
    missing_elecs.only_ieeg = B;
    pt(p).master_elecs.missing_elecs = missing_elecs;
end


end

function locs = add_loc_data(row,curr_label)
    locs.csv_file_name = row.Var1{1}; % electrode name per csv file
    locs.ieeg_name = curr_label; % ieeg electrode name
    if iscell(class(row.Var2))
        locs.anatomic = row.Var2{1}; % anatomic location
    else
        locs.anatomic = nan;
    end
    locs.system(1).locs = [row.Var3,row.Var4,row.Var5]; % some coordinate system
    locs.system(2).locs = [row.Var11,row.Var12,row.Var13]; % some other coordinate system
end