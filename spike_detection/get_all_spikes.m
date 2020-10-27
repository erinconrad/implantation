function get_all_spikes(overwrite)

%% General parameters
batch_time = 60;

%% Spike detector parameters
tmul = 15;
absthresh = 300;
min_chs = 2; % min number of channels
max_ch_pct = 80; % if spike > 80% of channels, throw away

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/'];
results_folder = [locations.main_folder,'results/'];
out_folder = [results_folder,'spikes/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));

%% Load pt file
pt = load([data_folder,'pt.mat']);
pt = pt.pt;

if exist(out_folder,'dir') == 0
    mkdir(out_folder)
end

for p = 1:length(pt)

for f = 1:length(pt(p).ieeg_names)
    
pt_name = pt(p).name;
fname = sprintf('%s_%d_spikes.mat',pt_name,f);

%% Check for existing files
clear spikes
if overwrite == 0
    if exist([out_folder,fname],'file') ~= 0
        spikes = load([out_folder,fname]);
        spikes = spikes.spikes;
        
        % Find last time
        start_time = spikes.start_time;
        
        fprintf('File already exists, loading and starting from last time.\n');
    else
        start_time = 0;
        spikes.name = pt_name;
        spikes.spikes = [];
    end
else
    start_time = 0;
    spikes.name = pt_name;
    spikes.spikes = [];
end

while 1
    
    fprintf('\nDoing time %1.1f s\n',start_time);
    
    %% Download data
    data = get_eeg(pt(p).ieeg_names{f},pwname,[start_time start_time+batch_time]);
    values = data.values;
    chLabels = data.chLabels(:,1);
    chIndices = 1:size(values,2);
    fs = data.fs;
    
    %% Check if it is all nans. If it is, move to the next file
    if sum(sum(~isnan(values))) == 0
        % breaking out of spike loop
        break
    end
    
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
    out = detect_spikes(values,tmul,absthresh,fs,min_chs,max_ch_pct);
    
    if ~isempty(out)
    
        %% Adjust times of spikes
        out = adjust_spike_times(out,start_time,fs);

        %% Re-derive original channels
        out = rederive_original_chs(chIndices,out,chLabels,data.chLabels(:,1));
    
    end
    
    %% Add data to structure and save
    spikes.spikes = [spikes.spikes;out];
    spikes.fs = fs;
    spikes.chLabels = chLabels;
    spikes.start_time = start_time+batch_time;
    save([out_folder,fname],'spikes');

    %% Move to next start time
    start_time = start_time+batch_time;
    
    whos
end

end
end
    

end