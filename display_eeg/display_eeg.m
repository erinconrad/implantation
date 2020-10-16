function display_eeg
tic
%% General parameters
p = 2;
f = 1;
start_time = 100000.92;
display_time = 60;

%% Spike detector parameters
tmul = 15;
absthresh = 300;
min_chs = 2; % min number of channels
max_ch_pct = 80; % if spike > 80% of channels, throw away

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));

%% Load pt file
pt = load([data_folder,'pt.mat']);
pt = pt.pt;

%% Initialize figure
figure
set(gcf,'position',[1 200 1400 800])


while 1
    
    %% Download data
    data = get_eeg(pt(p).ieeg_names{f},pwname,[start_time start_time+display_time]);
    values = data.values;
    chLabels = data.chLabels;
    chIndices = 1:size(values,2);
    fs = data.fs;
    
    non_ekg_chs = get_non_ekg_chs(chLabels);
    values(:,~non_ekg_chs) = [];
    chLabels(~non_ekg_chs) = [];
    chIndices(~non_ekg_chs) = [];
    
    %% Filters
    values = do_filters(values,fs);
    
    %% Remove artifact heavy channels
    bad = rm_bad_chs(values);
    values(:,bad) = [];
    chLabels(bad) = [];
    chIndices(bad) = [];
    
    %% Spike detection
    all_spikes = detect_spikes(values,tmul,absthresh,fs,min_chs,max_ch_pct);
    
    toc
    %% Plot data
    plot_signal(values,chLabels,display_time,all_spikes,fs,start_time)
    fprintf('\nPress any button to display next 15 seconds\n');
    pause
    hold off
    start_time = start_time+display_time;
end
    
    




end