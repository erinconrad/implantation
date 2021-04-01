function visualize_change_elecs(p)

%% Locations
pt_file = 'pt_w_elecs.mat';
locations = implant_files;
data_folder = [locations.main_folder,'data/data_files/'];
results_folder = [locations.main_folder,'results/'];
spike_folder = [results_folder,'spikes/'];
addpath(genpath(locations.script_folder));

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

%% Compare spike counts pre- and post- implantation
% Num pre implant and postimplant
num_pre = size(pt(p).pre_times,1);
pre = sum(all_counts(:,1:num_pre),2);
post = sum(all_counts(:,num_pre+1:end),2);

change = (post-pre);


stable = (all_elecs.change==0 & all_elecs.ekg_chs == 0);
new = (all_elecs.change==1 & all_elecs.ekg_chs == 0);
rm = (all_elecs.change==2 & all_elecs.ekg_chs == 0);
change(~stable) = [];

%% Find electrodes with very few spikes pre-implant and a decent number post
max_pre = 5;
min_post = 100;
big_change = pre < max_pre & post > min_post & stable;
not_big_change = (pre >= max_pre | post < min_post) & stable;

%% Get locs
all_locs = get_loc_array(all_elecs,1);
stable_locs = all_locs(stable,:);
new_locs = all_locs(new,:);
rm_locs = all_locs(rm,:);

%% Get closest new elec to each stable elec
nall = size(all_locs,1);
d = nan(nall,1);
for i = 1:nall
    cl = all_locs(i,:);
    min_dist = min(vecnorm(new_locs-repmat(cl,size(new_locs,1),1),2,2));
    d(i) = min_dist;
end

[~,pval] = ttest2(d(big_change),d(not_big_change));

%% Plot
msize = 200;
figure
%scatter3(stable_locs(:,1),stable_locs(:,2),stable_locs(:,3),100,change,'filled');
scatter3(all_locs(big_change,1),all_locs(big_change,2),all_locs(big_change,3),...
    msize,'r','filled');
hold on
scatter3(stable_locs(:,1),stable_locs(:,2),stable_locs(:,3),msize,'k');
scatter3(new_locs(:,1),new_locs(:,2),new_locs(:,3),msize,'gp','filled');
scatter3(rm_locs(:,1),rm_locs(:,2),rm_locs(:,3),msize,'bs');
axis('off')
title(sprintf('t-test p = %1.3f',pval))

end