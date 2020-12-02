function changing_dist(p)

pt_file = 'pt_w_elecs.mat';

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/data_files/'];
results_folder = [locations.main_folder,'results/'];
spike_folder = [results_folder,'spikes/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));

%% Load files
pt = load([data_folder,pt_file]);
pt = pt.pt;

pt_name = pt(p).name;

if ~isfield(pt(p).master_elecs,'locs')
    fprintf('\nNo electrode locations for %s, quitting.\n',pt_name);
    return
end

spikes = load([spike_folder,sprintf('%s_spikes.mat',pt_name)]);
spikes = spikes.spikes;

%% Make master list of electrodes
%all_elecs = master_list_elecs(pt,p);
all_elecs = pt(p).master_elecs;

%% Go through all spikes and convert chs to the master indices
for w = 1:length(spikes.spikes)
    curr_window = spikes.spikes(w);
    f = curr_window.times(3); % get the file
    
    % Get current spikes
    curr_spikes = curr_window.spikes;
    
    if isempty(curr_spikes)
        spikes.spikes(w).new_spikes = [];
        continue; 
    end
    chs = curr_spikes(:,2);
    
    % get the indices of the electrodes for that file within the master
    % list of electrodes
    indices = all_elecs.idx{f};
    
    % convert chs to these new indices
    new_chs = indices(chs);
    
    new_spikes = [curr_spikes(:,1),new_chs];
    spikes.spikes(w).new_spikes = new_spikes;
end

%% Get counts in each window and concatenate
all_counts = zeros(size(all_elecs.master_labels,1),length(spikes.spikes));
for w = 1:length(spikes.spikes)
    spikes.spikes(w).counts = zeros(size(all_elecs.master_labels,1),1);
    if isempty(spikes.spikes(w).new_spikes)
        continue; 
    end
    for ch = 1:length(spikes.spikes(w).counts)
        spikes.spikes(w).counts(ch) = sum(spikes.spikes(w).new_spikes(:,2) == ch);
    end
    
    all_counts(:,w) = spikes.spikes(w).counts;
end

%% Get distances from closest new electrodes
[dist,closest_elecs,new_locs,new_elecs] = distance_from_closest_new_elecs(pt,p);

%% Convert all_counts to average distance of spikes from new electrodes over time
avg_dist = all_counts.*dist;
avg_dist = nansum(avg_dist,1);

plot(avg_dist)

%% Compare average distance of spikes to new electrodes
[~,p] = ttest2(avg_dist(1:50),avg_dist(51:100))

end