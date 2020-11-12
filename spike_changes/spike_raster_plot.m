function spike_raster_plot(p)

%% Parameters
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


%% Raster plot
figure
set(gcf,'position',[399 1 560 800])
imagesc(all_counts(all_elecs.change==0,:));
yticks(1:length(all_counts(all_elecs.change==0,:)))
yticklabels(all_elecs.master_labels(all_elecs.change==0))
title('Unchanged electrodes')
set(gca,'fontsize',10)

figure
imagesc(all_counts(all_elecs.change==1,:));
yticks(1:length(all_counts(all_elecs.change==1,:)))
yticklabels(all_elecs.master_labels(all_elecs.change==1))
title('New electrodes')

%{
subplot(3,1,1)
imagesc(all_counts(all_elecs.change==0,:));

subplot(3,1,2)
imagesc(all_counts(all_elecs.change==1,:));

subplot(3,1,3)
imagesc(all_counts(all_elecs.change==2,:));
%}

end