function total_count = overall_spike_rate(p)

%% Parameters
do_plot = 1;

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/data_files/'];
results_folder = [locations.main_folder,'results/'];
spike_folder = [results_folder,'spikes/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));
pt_file = 'pt_w_elecs.mat';

%% Load files
pt = load([data_folder,pt_file]);
pt = pt.pt;

pt_name = pt(p).name;

spikes = load([spike_folder,sprintf('%s_spikes.mat',pt_name)]);
spikes = spikes.spikes;

%% Make master list of electrodes
all_elecs = master_list_elecs(pt,p);

%% Spike times
times = spikes.times(:,1);

% Reimplantation time
reimplantation_file = pt(p).elec_change_files;
reimplantation_time = convert_file_time_to_total_time(pt,p,0,reimplantation_file);

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

%% Get channels to ignore
% Ignore channels that are not always there
changing_elecs = logical(all_elecs.change ~= 0);

% Combine things I'm ignoring
ignore_elecs = changing_elecs;

%% Add up remaining elecs
total_count = sum(all_counts(~ignore_elecs,:));

%% Plot total count
if do_plot == 1
figure
set(gcf,'position',[440 370 952 428])
plot(times/3600,total_count,'linewidth',2)
hold on
xlabel('Time (h)')
ylabel('Spike counts')
re_p = plot([reimplantation_time reimplantation_time]/3600,get(gca,'ylim'),'linewidth',2);
legend(re_p,'Reimplantation','fontsize',20)
set(gca,'fontsize',20)
end



end