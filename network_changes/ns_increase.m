function ns_increase(p)

pt_file = 'pt_w_elecs.mat';

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/data_files/'];
results_folder = [locations.main_folder,'results/'];
network_folder = [results_folder,'networks/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));

%% Load files
pt = load([data_folder,pt_file]);
pt = pt.pt;

pt_name = pt(p).name;
small = load([network_folder,sprintf('%s_small.mat',pt_name)]);
small = small.small;

%ns_norm = small.ns_norm;
ns_norm = small.ec;

elecs = pt(p).master_elecs;
change = elecs.change; % change status of electrodes
ekg = elecs.ekg_chs; % are they ekg channels?
n_elecs = sum(change == 0 & ekg == 0);
labels = elecs.master_labels;

if n_elecs ~= size(ns_norm,1)
    error('Electrode info does not match')
end

%% Get distances from closest new electrodes
[dist,closest_elecs,new_locs,new_elecs] = distance_from_closest_new_elecs(pt,p);
dist = dist(change == 0 & ekg == 0);
labels = labels(change == 0 & ekg == 0);

%% Compare node strength before and after reimplantation
% Num pre implant and postimplant
num_pre = size(pt(p).pre_times,1);
pre = nanmean(ns_norm(:,1:num_pre),2);
post = nanmean(ns_norm(:,num_pre+1:end),2);

%% Compute relative change
rel_change = (post-pre)./abs(pre);

%% Raster plot
figure
imagesc(ns_norm)
hold on
rp = plot([size(ns_norm,2)/2 size(ns_norm,2)/2],get(gca,'ylim'),'r','linewidth',2);
yticks(1:length(labels))
yticklabels(labels)

%% Scatter plot
figure
scatter(rel_change,dist,'filled')
for i = 1:length(labels)
    text(rel_change(i),dist(i),labels{i},'fontsize',15)
end

end