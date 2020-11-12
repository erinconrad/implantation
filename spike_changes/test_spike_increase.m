function test_spike_increase(p)

%{
This tests the hypothesis that implanting electrodes transiently increases
spike rates in the region of the electrodes.

The prediction is that the spike rates in the electrodes close to the newly
implanted electrodes are disproportionately increased relative to other
electrodes

I will calculate the relative change in spike rates in electrodes. I will
remove electrodes for which there are barely any spikes overall. 

I will then sort the electrodes by relative change.

I will separately sort the electrodes by inverse distance from the newly implanted
electrodes.

I will calculate the Spearman rank coefficient. A higher coefficient
goes along with closer electrodes having greater increase in spike rate.
%}

%% Parameters
min_sp = 10;
n_std = 2;
nboot = 1e4;
pt_file = 'pt_w_elecs.mat';
do_rel = 0;

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

spikes = load([spike_folder,sprintf('%s_spikes.mat',pt_name)]);
spikes = spikes.spikes;

%% Make master list of electrodes
all_elecs = master_list_elecs(pt,p);

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

%% Compare spike counts in first 5 blocks after each implantation
%pre = sum(all_counts(:,1:5),2);
pre = sum(all_counts(:,1:20),2);
post = sum(all_counts(:,21:40),2);


%% Compute relative change
if do_rel == 1
    rel_change = (post-pre)./pre;
else
    rel_change = post;
end

%% Get distances from closest new electrodes
dist = distance_from_closest_new_elecs(pt,p);

%% Get channels to ignore
% Ignore channels for which number of spikes is less than minimum
few_spikes = logical(pre+post < min_sp);

% Ignore channels that are not always there
changing_elecs = logical(all_elecs.change ~= 0);

% Combine things I'm ignoring
ignore_elecs = few_spikes | changing_elecs;

% Remove electrodes from both rel_change and dist
rel_change(ignore_elecs) = [];
dist(ignore_elecs) = [];
new_labels = all_elecs.master_labels;
new_labels(ignore_elecs) = [];

%% Get the Spearman rank correlation between the relative change and 1/dist vectors
inv_dist = 1./dist;
[rho,pval] = corr(rel_change,dist,'Type','Spearman');
if 1
figure
scatter(rel_change,dist,'filled')
if pval<0.001
    title(sprintf('%s\nSpearman rank correlation: rho = %1.1f, p < 0.001',pt_name,rho))
else
    title(sprintf('%s\nSpearman rank correlation: rho = %1.1f, p = %1.3f',pt_name,rho,pval))
end

xlabel('Relative change in spike count')
ylabel('Distance from closest new electrodes')
set(gca,'fontsize',20);
end

%% Find those electrodes with a substantial increase in spike rate
min_rel_change = mean(rel_change) + n_std*std(rel_change);
elec_inc = find(rel_change > min_rel_change);

%% Get mean distance from these electrodes to new electrodes
dist_inc = mean(dist(elec_inc));

%% Do a permutation test to get statistics
% I will randomly choose the same number of electrodes to be my
% "substantial increase electrodes" and calculate their mean distance and
% then I will do this 10,000 times and get the distribution of distances
% under the null distribution

% One problem with this is that electrodes that are closer together are
% more likely to have a similar increase in spikes, even if this is not 
% driven by distance from new electrodes. Need to think about this.

dist_boot = zeros(nboot,1);
for ib = 1:nboot
    
    % Randomly choose same number of electrodes as those with substantial
    % increase in spike rate
    idx = randsample(length(rel_change),length(elec_inc));
    
    % Get their mean distance from new electrodes
    dist_temp = mean(dist(idx));
    dist_boot(ib) = dist_temp;
end

% Sort the bootstrap data
dist_boot = sort(dist_boot);

% Find bootstrap distances smaller than or equal to our true distance
n_more_extreme = sum(dist_boot <= dist_inc);
p_val = n_more_extreme/nboot;
if p_val == 0 
    p_val = 1/(nboot+1);
end

if 0
    figure
    plot(dist_boot,'o')
    hold on
    plot(get(gca,'xlim'),[dist_inc dist_inc])
    if p_val < 0.001
        title(sprintf('Permutation test p-value < 0.001'))
    else
        title(sprintf('Permutation test p-value %1.3f',p_val))
    end
    xlabel('Permutation')
    ylabel(sprintf('Average distance from\nclosest new electrode'))
    set(gca,'fontsize',20);
end



end
