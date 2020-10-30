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

out.labels = all_labels;
out.idx = all_idx;
out.master_labels = master_labels;


end