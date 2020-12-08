function display_eeg

%% General parameters
p = 6;
f = [];
start_time = 660450.10;
display_time = 60;
do_analysis = 1;

%% Spike detector parameters
tmul = 15;
absthresh = 300;
min_chs = 2; % min number of channels
max_ch_pct = 80; % if spike > 20% of channels, throw away

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/data_files/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));

%% Load pt file
pt = load([data_folder,'pt_w_elecs.mat']);
pt = pt.pt;

%% Pick random times if not specified
if isempty(f)
    % Pick a random pre-reimplantation index
    i = randi(size(pt(p).pre_times,1));
    %i = 34;
    
    f = pt(p).pre_times(i,2);
    start_time = pt(p).pre_times(i,3);
end

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
        
        
        %% Filters
        values = do_filters(values,fs);
        orig_values = values;
        orig_labels = chLabels;
        
        %% Remove artifact heavy channels

        
        bad = rm_bad_chs(values,fs,chLabels);
        bad(~non_ekg_chs) = 1;
        values(:,bad) = [];
        chLabels(bad) = [];
        chIndices(bad) = [];
        
        %{
        values(:,~non_ekg_chs) = [];
        chLabels(~non_ekg_chs) = [];
        chIndices(~non_ekg_chs) = [];
        %}
        

        %}
        
        

        %% Spike detection
        all_spikes = detect_spikes(values,tmul,absthresh,fs,min_chs,max_ch_pct);
        
        if ~isempty(all_spikes)
            %% Spikes on EKG
            
            ekg_spikes = detect_spikes(orig_values(:,~non_ekg_chs),tmul,absthresh,fs,0,100);
            if ~isempty(ekg_spikes)
            all_spikes = remove_ekg(all_spikes,ekg_spikes,fs);
            end

            %% Re-derive original channels
            out = rederive_original_chs(chIndices,all_spikes,chLabels,data.chLabels(:,1));
        else
            
            out = [];
        end
        toc
    else
        all_spikes = [];
        out = [];
    end
    
    %% Plot data
    %plot_signal(values,chLabels,display_time,all_spikes,fs,start_time)
    plot_signal(orig_values,orig_labels,display_time,out,fs,start_time,bad)
    start_time
    f
    fprintf('\nSpeed of %1.1f\n',display_time/toc);
    fprintf('\nPress any button to display next time\n');
    pause
    hold off
    start_time = start_time+display_time;
end
    
    




end