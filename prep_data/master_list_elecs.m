%{
This function takes a list of all electrode labels from all files and
returns a master list of electrodes and the indices of the file-specific
labels within that
%}

function out = master_list_elecs(pt,p)

nfiles = length(pt(p).filename);
all_labels = cell(nfiles,1);
master_labels = {};
all_idx = cell(nfiles,1);

for f = 1:nfiles
    all_labels{f} = pt(p).filename(f).chLabels;
    master_labels = [master_labels;pt(p).filename(f).chLabels];
end

%% Get list of unique labels from all the labels for that patient
master_labels = unique(master_labels);


%% Go through each file and get the index for each label in the master list
for f = 1:nfiles
    curr_labels = all_labels{f};
    curr_idx = zeros(length(curr_labels),1);
    for i = 1:length(curr_labels)
        [check,curr_idx(i)] = ismember(curr_labels{i},master_labels);
        
        % Make sure I found it
        if check == 0
            error('Could not find electrode %s',curr_labels{i});
        end
        
        
    end
    
    all_idx{f} = curr_idx;
end

%% Go through and find electrodes that change (go away or newly come up)
out.change = zeros(size(master_labels,1),1);
out.labels = all_labels;
out.idx = all_idx;
out.master_labels = master_labels;

% Confirm only one file that changes
change_file = pt(p).elec_change_files;
if length(change_file) > 1
    error('I do not know how to handle multiple changes');
elseif isempty(change_file)
    return
end

% compare pre and post change files
old_idx = all_idx{change_file-1};
new_idx = all_idx{change_file};
new = setdiff(new_idx,old_idx);
old = setdiff(old_idx,new_idx);
out.change(new) = 1;
out.change(old) = 2;


%% Denote ekg
non_ekg_chs = get_non_ekg_chs(pt(p).master_elecs.master_labels);
ekg_chs = logical(~non_ekg_chs);
out.ekg_chs = ekg_chs;


end