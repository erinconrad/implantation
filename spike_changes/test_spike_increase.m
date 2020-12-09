function [pvaltt,tstat] = test_spike_increase(p)

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
do_plot = 1;
min_sp = 1e2;
n_std = 2;
top_perc = 5;
nboot = 1e4;
pt_file = 'pt_w_elecs.mat';
do_rel = 1;
do_boot = 1;
perc_closest_elecs = 0.05;
early_post_implant = 51:60;
late_post_implant = 91:100;

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

%% Compare spike counts in first 5 blocks after each implantation
%pre = sum(all_counts(:,1:5),2);
% Num pre implant and postimplant

num_pre = size(pt(p).pre_times,1);
pre = sum(all_counts(:,1:num_pre),2);
post = sum(all_counts(:,num_pre+1:end),2);



%% Compute relative change
if do_rel == 1
    rel_change = (post-pre)./pre;
else
    rel_change = post;
end

%% Get distances from closest new electrodes
[dist,closest_elecs,new_locs,new_elecs] = distance_from_closest_new_elecs(pt,p);

%% Get channels to ignore
% Ignore EKG channels
non_ekg_chs = get_non_ekg_chs(pt(p).master_elecs.master_labels);
ekg_chs = logical(~non_ekg_chs);

% Ignore channels for which number of spikes is less than minimum
%few_spikes = logical(pre+post < min_sp);

% Ignore channels that are not always there
changing_elecs = logical(all_elecs.change ~= 0);
% Combine things I'm ignoring
%ignore_elecs = few_spikes | changing_elecs | ekg_chs;
ignore_elecs = changing_elecs | ekg_chs;

% Remove electrodes from both rel_change and dist
pre(ignore_elecs) = [];
post(ignore_elecs) = [];
rel_change(ignore_elecs) = [];
dist(ignore_elecs) = [];
new_labels = all_elecs.master_labels;
new_labels(ignore_elecs) = [];
closest_elecs(ignore_elecs) = [];
all_counts(ignore_elecs,:) = [];

%% Find those electrodes with a substantial increase in spike rate
min_rel_change = mean(rel_change) + n_std*std(rel_change);
%{
[~,I] = sort(rel_change);
num_special = round(length(I)*top_perc/100);
elec_inc = I(end-num_special:end);
special = ismember(1:length(I),elec_inc);
%}
special = rel_change > min_rel_change & pre+post > min_sp;
elec_inc = find(special);
%}

%% List the top 5 spike rate increase electrodes
if 1
[~,big_inc] = sort(rel_change,'descend');
for i = 1:5
    
    fprintf('\nHigh spike rate increase electrode: %s\n',new_labels{big_inc(i)});
    
    % Get the anatomical location
    master_idx = find(strcmp(pt(p).master_elecs.master_labels,new_labels{big_inc(i)}));
    fprintf('\nThis electrode is in: %s\n',pt(p).master_elecs.locs(master_idx).anatomic);
   
    % Get its nearest electrode
    close = closest_elecs(big_inc(i));
    fprintf('Its closest new electrode is %s,',all_elecs.master_labels{close});
    
    % Distance between the two
    fprintf('which is %1.1f away.\n',dist(big_inc(i)));
    
    % Sanity check 1 (checking that distance is what I think it is)
    alt_dist = distance_two_elecs(pt,p,new_labels{big_inc(i)},all_elecs.master_labels{close});
    if alt_dist ~= dist(big_inc(i))
        error('what');
    end
    
    % Sanity check 2 (confirming that the closest electrode is the one I
    % found)
    curr_ind = find(strcmp(all_elecs.master_labels,new_labels{big_inc(i)}));
    curr_loc = all_elecs.locs(curr_ind).system(1).locs;
    min_dist = inf;
    closest_check = nan;
    for n = 1:size(new_locs,1)
        if vecnorm(curr_loc-new_locs(n,:)) < min_dist
            min_dist = vecnorm(curr_loc-new_locs(n,:));
            closest_check = n;
        end
    end
    closest_elec_check = new_elecs(closest_check);
    closest_label = all_elecs.master_labels(closest_elec_check);
    if min_dist ~= alt_dist
        error('what');
    end

    if ~strcmp(closest_label,all_elecs.master_labels{close})
        error('what');
    end
end
end

if do_boot



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

%% Non-bootstrap test - independent two-sample t-test and Wilcoxon rank sum
% Compare the distances between the high increase electrodes and low
if sum(special) > 0
[~,pvaltt,~,stats_tt] = ttest2(dist(special),dist(~special));
fprintf('\nUsing a two-sample t-test, p-value is %1.3f\n',pvaltt);
tstat = stats_tt.tstat;

[pvalrs,~,stats] = ranksum(dist(special),dist(~special));
fprintf('\nUsing a Wilcoxon rank sum test, p-value is %1.3f\n',pvalrs);
else
    pvaltt = nan;
end


if do_plot
figure
scatter(rel_change,dist,'filled')
for i = 1:length(new_labels)
    if 1%rel_change(i) > min_rel_change
        if special(i) == 1
            text(rel_change(i),dist(i),new_labels{i},'fontsize',15,'color','b')
        else
            text(rel_change(i),dist(i),new_labels{i},'fontsize',15)
        end
    end
end
%
%[rho,pval] = corr(rel_change,dist,'Type','Spearman');
if pvaltt<0.001
    title(sprintf('T-test p-value < 0.001'))
    %title(sprintf('%s\nSpearman rank correlation: rho = %1.1f, p < 0.001',pt_name,rho))
else
    title(sprintf('T-test p-value %1.3f',pvaltt))
    %title(sprintf('%s\nSpearman rank correlation: rho = %1.1f, p = %1.3f',pt_name,rho,pval))
end
%}


xlabel('Relative change in spike count')
ylabel('Distance from closest new electrodes')
set(gca,'fontsize',20);
print(gcf,[results_folder,'increase_distance/',sprintf('%s',pt_name)],'-dpng')
end

end

if 0 
%% Now see if these electrode spike rates (1) decrease after implantation and (2) decrease more than most electrodes
% Compare the spike rates early and late post-implant
early_rate_special = mean(mean(all_counts(rel_change > min_rel_change,early_post_implant)));
late_rate_special = mean(mean(all_counts(rel_change > min_rel_change,late_post_implant)));
fprintf('\n\nThe average early post-implant spike rate of highest relative increase is %1.1f per period.\n',early_rate_special);
fprintf('\n\nThe average late post-implant spike rate of highest relative increase is %1.1f per period.\n',late_rate_special);

%% Plot the spike rate in these channels over time
if 1
figure
plot(mean(all_counts(rel_change > min_rel_change,:),1))
hold on
title('Average spike rates of highest rate increase electrodes')
xlabel('Time period')
ylabel('Number of spikes')
set(gca,'fontsize',20)
rp = plot([size(all_counts,2)/2 size(all_counts,2)/2],get(gca,'ylim'));
legend(rp,'Re-implantation','fontsize',20)
end
end

%% Alternate approach - do electrodes close to new electrodes have higher spike rate increases?
% No
%{
n_closest_elecs = round(perc_closest_elecs*length(dist));
[~,sorted_dist_ind] = sort(dist);
[~,pval,~,stats] = ttest2(rel_change(sorted_dist_ind(1:n_closest_elecs)),...
    rel_change(sorted_dist_ind(n_closest_elecs+1:end)));
%}
end
