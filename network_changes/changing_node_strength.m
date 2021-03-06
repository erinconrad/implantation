function changing_node_strength(p)

do_plot = 0;

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
networks = load([network_folder,sprintf('%s_network.mat',pt_name)]);
networks = networks.networks;

%% Make master list of electrodes
%all_elecs = master_list_elecs(pt,p);
all_elecs = pt(p).master_elecs;
change = all_elecs.change; % change status of electrodes
ekg = all_elecs.ekg_chs; % are they ekg channels?
n_elecs = sum(change == 0 & ekg == 0);
n_times = length(networks.networks);

%% Initialize node strength array
ns_all = nan(n_elecs,n_times);
ns_norm_all = nan(n_elecs,n_times);
ec_all = nan(n_elecs,n_times);
ec_norm_all = nan(n_elecs,n_times);

% Loop over times
for i = 1:length(networks.networks)

    % Get channel labels
    chLabels = networks.networks(i).chLabels;
    
    if isempty(chLabels)
        continue;
    end
    
    % Get change status of these labels
    change_status = zeros(length(chLabels),1);
    for j = 1:length(chLabels)
        label = chLabels{j};
        id = change(strcmp(label,all_elecs.master_labels));
        change_status(j) = id;
    end
    
    % Get those electrodes that do not change
    no_change = change_status == 0;
    
    % Average adjacency matrices for each 30 minute period
    adj = nanmean(networks.networks(i).networks,2);
    
    % Also, normalize values (so that one really high correlation period
    % doesn't throw off everything) - will be helpful to look for relative
    % changes between electrodes
    nets = networks.networks(i).networks;
    nets_normalized = (nets - nanmean(nets,1))./nanstd(nets,0,1);
    adj_norm = nanmean(nets_normalized,2);
    
    
    % Re-expand
    adj = flatten_or_expand_adj(adj);
    adj_norm = flatten_or_expand_adj(adj_norm);
    
    % Only keep rows and columns that do not change
    adj_no_change = adj(no_change,no_change);
    adj_norm_no_change = adj_norm(no_change,no_change);
    
    if size(adj_no_change,1) ~= n_elecs
        error('Sizes do not match')
    end
    
    % Get node strength
    ns = nansum(adj_no_change,1);
    ns_norm = nansum(adj_norm_no_change,1);
    
    ns_all(:,i) = ns;
    ns_norm_all(:,i) = ns_norm;
    try
        ec_all(:,i) = compute_ec(adj_no_change);
        ec_norm_all(:,i) = compute_ec(adj_norm_no_change);
    catch
        fprintf('\nWarning, nans for period %d\n',i);
        ec_norm_all(:,i) = nan;
        ec_all(:,i) = nan;
    end
    
end

%% Raster plot
if do_plot
figure
set(gcf,'position',[399 1 560 800])
imagesc(ns_all);
hold on
yticks(1:size(ns_all,1))
yticklabels(all_elecs.master_labels(all_elecs.change==0& ekg == 0))
set(gca,'fontsize',10)
xlabel('Time period','fontsize',20)
ylabel('Electrode','fontsize',20)
title('Node strength by electrode','fontsize',20)
end

%% Save new structure
small.name = pt_name;
small.ns = ns_all;
small.ns_norm = ns_norm_all;
small.ec = ec_all;
small.ec_norm = ec_norm_all;
save([network_folder,sprintf('%s_small.mat',pt_name)],'small');



end