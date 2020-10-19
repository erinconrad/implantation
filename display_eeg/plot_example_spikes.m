function plot_example_spikes

%% General parameters
p = 1;
f = 1;
surround = 7.5;
sp = 83;

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/'];
results_folder = [locations.main_folder,'results/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));
spike_folder = [results_folder,'spikes/'];

%% Load pt file
pt = load([data_folder,'pt.mat']);
pt = pt.pt;
pt_name = pt(p).name;

    
%% Load spike file
spikes = load([spike_folder,sprintf('%s_%d_spikes.mat',pt_name,f)]);
spikes = spikes.spikes;

while 1

    %% Get info about the spike
    curr_spike = spikes.spikes(sp,:);
    sp_time = curr_spike(1);
    sp_ch = curr_spike(2);

    %% Get the EEG data
    data = get_eeg(pt(p).ieeg_names{f},pwname,[sp_time-surround sp_time+surround]);
    values = data.values;
    chLabels = data.chLabels(:,1);
    chIndices = 1:size(values,2);
    fs = data.fs;
    
    sp_index = surround*fs;

    %% Plot data
    plot_signal(values,chLabels,surround*2,[sp_index sp_ch],fs,sp_time-surround)
    pause
    hold off
    sp = sp + 1;
    
end

end