function display_eeg

%% General parameters
p = 4;
f = 1;
start_time = 76370;
display_time = 600;
do_analysis = 0;

%% Spike detector parameters
tmul = 15;
absthresh = 300;
min_chs = 2; % min number of channels
max_ch_pct = 80; % if spike > 80% of channels, throw away

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/data_files/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));

%% Load pt file
pt = load([data_folder,'pt_w_elecs.mat']);
pt = pt.pt;

%% Initialize figure
figure
set(gcf,'position',[1 200 1400 800])


while 1
    tic
    %% Download data
    data = get_eeg(pt(p).ieeg_names{f},pwname,[start_time start_time+display_time]);
    values = data.values;
    chLabels = data.chLabels(:,1);
    chIndices = 1:size(values,2);
    fs = data.fs;
    
    if do_analysis
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

        %% Re-derive original channels
        if ~isempty(all_spikes)
            out = rederive_original_chs(chIndices,all_spikes,chLabels,data.chLabels(:,1));
        end
        toc
    else
        all_spikes = [];
    end
    
    %% Plot data
    plot_signal(values,chLabels,display_time,all_spikes,fs,start_time)
    fprintf('\nSpeed of %1.1f\n',display_time/toc);
    fprintf('\nPress any button to display next time\n');
    pause
    hold off
    start_time = start_time+display_time;
end
    
    




end