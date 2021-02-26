clear

%% Parameters
detector = 'erin';
pt_name = 'HUP075';
which_spikes = 1:10;
surround_time = 3; % how many s before and after
which_chs = [];%{'AMY1','AMY2'};
show_bad = 1;


%% Locations
locations = implant_files;
pwname = locations.pwfile;
scripts_folder = [locations.main_folder,'scripts/'];
addpath(genpath(scripts_folder));
spike_folder = [locations.main_folder,'../spike_networks/data/manual_spikes/'];
spike_file = [spike_folder,'manual spikes.xlsx'];

if isempty(locations.ieeg_folder) == 0
    addpath(genpath(locations.ieeg_folder));
end

% Note that these are pts from spike_networks project
pt_folder = [locations.main_folder,'../spike_networks/data/spike_structures/'];
pt = load([pt_folder,'pt.mat']);
pt = pt.pt;

% Find the pt number
found_it = 0;
for p = 1:length(pt)
    if strcmp(pt(p).name,pt_name)
        found_it = 1;
        break;
    end
end
if found_it == 0, error('what'); end
ieeg_name = pt(p).ieeg_name;

%% Load spike time file
T = readtable(spike_file);
spike_times = T.(pt_name);

%% Get eeg data for spike
for s = which_spikes
    start_time = spike_times(s) - surround_time;
    batch_time = surround_time * 2;
    data = get_eeg(ieeg_name,pwname,[start_time start_time+batch_time]);
    values = data.values;
    fs = data.fs;
    chLabels = data.chLabels;
    chLabels = chLabels(:,1);


    %% Pre-processing
    chLabels = clean_labels(chLabels);


    values = do_filters(values,fs,chLabels);
    chIndices = 1:size(values,2);
    orig_labels = chLabels;
    orig_values = values;

    non_ekg_chs = get_non_ekg_chs(chLabels);
    values(:,~non_ekg_chs) = [];
    chLabels(~non_ekg_chs) = [];
    chIndices(~non_ekg_chs) = [];

    %% remove bad channels
    bad = rm_bad_chs(values,fs,chLabels);
    values(:,bad) = [];
    chLabels(bad) = [];
    chIndices(bad) = [];

    %% Spike detection
    switch detector
        case 'fspk2'
        % FSPK2
        tmul = 15;
        absthresh = 300;
        n_chans = size(values,2);
        gdf = fspk2(values,tmul,absthresh,n_chans,fs);
        
        case 'wavelet'
        wavelet_detector(values,fs);
        
        case 'erin'
        gdf = erin_simple(values,fs);

    end

    %% Plotting
    spikes = gdf;
    easy_plot(values,chLabels,[0 surround_time*2],which_chs,spikes,orig_values,orig_labels,show_bad)
    pause
    close(gcf)
end

