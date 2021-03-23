

function tune_detectors(p,start_time,tmul,absthresh,min_chs)

%% General parameters
do_plot = 1;
do_save = 0;
batch_time = 15;
pt_name = [];
max_ch_pct = 50; % if spike > 50% of channels, throw away

allowable_time_from_zero = 0.1; % 100 ms
rm_bad = 1;


%% Locations
locations = implant_files;
pwname = locations.pwfile;
scripts_folder = [locations.script_folder];
data_folder = [locations.main_folder,'data/data_files/'];
results_folder = [locations.main_folder,'results/'];
addpath(genpath(scripts_folder));
addpath(genpath(locations.ieeg_folder));


pt = load([data_folder,'pt_w_elecs.mat']);
pt = pt.pt;



pt_name = pt(p).name;
% Always first file
if p == 3
    f = 2;
else
    f = 1;
end
ieeg_name = pt(p).ieeg_names{f};


%% Start getting data
% Loop through spikes
while 1
    
    %% Get eeg data
    data = get_eeg(ieeg_name,pwname,[start_time start_time+batch_time]);
    values = data.values;
    fs = data.fs;
    chLabels = data.chLabels;
    duration = size(values,1)/fs;
    

    %% Pre-processing
    chIndices = 1:size(values,2);
    values = do_filters(values,fs,chLabels);
    
    non_ekg_chs = get_non_ekg_chs(chLabels);
    orig_labels = chLabels;
    chLabels = clean_labels(chLabels);
    new_orig_labels  = chLabels;
    orig_values = values;


    %% remove bad channels
    if 1
        bad = rm_bad_chs(values,fs,chLabels);
        bad(~non_ekg_chs) = 1;
        values(:,bad) = [];
        chLabels(bad) = [];
        chIndices(bad) = [];
    end

    %% Spike detection
    out = detect_spikes(values,tmul,absthresh,fs,min_chs,max_ch_pct,[]);
    
    if ~isempty(out)
        indices = out(:,1);
        out = adjust_spike_times(out,start_time,fs);

        %% Re-derive original channels
        out = rederive_original_chs(chIndices,out,chLabels,new_orig_labels);
    else
        indices = [];
    end


    %% Plotting
    plot_signal(orig_values,new_orig_labels,batch_time,out,indices,fs,start_time,bad);
    
    start_time = start_time + batch_time;
   

end



end
