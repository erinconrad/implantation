

clear

%% Parameters
overwrite = 0;
detector = 'erin';
pt_name = 'HUP075';
do_plot = 0;
do_save = 1;
allowable_time_from_zero = 0.1; % 100 ms
rm_bad = 0;

%% Locations
locations = implant_files;
pwname = locations.pwfile;
scripts_folder = [locations.main_folder,'scripts/'];
results_folder = [locations.main_folder,'results/'];
addpath(genpath(scripts_folder));
out_folder = [results_folder,'testing/',detector,'/'];
if ~exist(out_folder,'dir')
    mkdir(out_folder);
end

%% Get data
% Note that these are pts from spike_networks project
pt_folder = [locations.main_folder,'../spike_networks/data/spike_structures/'];
pt = load([pt_folder,'pt.mat']);
pt = pt.pt;
eeg_data_folder = [locations.main_folder,'../spike_networks/results/eeg_data/'];
listing = dir([eeg_data_folder,'*.mat']);
pt_names = cell(length(listing),1);
for i = 1:length(listing)
    fname = listing(i).name;
    C = strsplit(fname,'_');
    curr_pt_name = C{1};
    pt_names{i} = curr_pt_name;
end

%% Get the correct pts
if ~isempty(pt_name)
    which_pts = find(strcmp(pt_name,pt_names));
else
    which_pts = 1:length(listing);
end

t = 0;

% Loop through patients
for i = 1:length(which_pts)
    
    p = which_pts(i); % pt index
    name = pt_names{p};
    fprintf('\n\n\nDoing %s (patient %d of %d)\n',name,i,length(which_pts));
    
    %% Load spike and eeg data
    spike = load([eeg_data_folder,name,'_eeg.mat']);
    spike = spike.spike;
    fs = spike(1).fs;
    
    %% See if the output file exists already
    if overwrite == 0
        if exist([out_folder,name,'_test.mat'],'file') ~= 0
            % Load the file
            test = load([out_folder,name,'_test.mat']);
            test = test.test;
            last_spike = length(test.spike);
        else
            test.name = name;
            test.fs = fs;
            test.chLabels = spike(1).chLabels;
            last_spike = 0;
        end
    end
    
    % Are we done already?
    if last_spike + 1 == length(spike)
        fprintf('\nAlready completed %s.',name);
        continue;
    end
    
    test.name = name;
    test.fs = fs;
    test.chLabels = spike(1).chLabels;

    %% Start getting data
    % Loop through spikes
    for j = last_spike+1:length(spike)
        tic
        fprintf('Doing spike %d of %d (last took %1.1fs)\n',j,length(spike),t);
        s = j;
        
        test.spike(s).times = spike(s).times;
        
        %% Get eeg data
        values = spike(s).data;
        chLabels = spike(s).chLabels;
        duration = size(values,1)/fs;

        %% Pre-processing
        values = do_filters(values,fs,chLabels);
        chIndices = 1:size(values,2);
        orig_labels = chLabels;
        orig_values = values;


        %% remove bad channels
        if rm_bad
            bad = rm_bad_chs(values,fs,chLabels);
            values(:,bad) = [];
            chLabels(bad) = [];
            chIndices(bad) = [];
        end

        %% Spike detection
        switch detector
            case 'fspk2'
            % FSPK2
            tmul = 15;
            absthresh = 300;
            n_chans = size(values,2);
            gdf = fspk2(values,tmul,absthresh,n_chans,fs);

            case 'wavelet'
            gdf = wavelet_detector(values,fs);

            case 'erin'
            gdf = erin_simple(values,fs);

        end

        %% Plotting
        if do_plot
            easy_plot(values,chLabels,[0 duration],[],gdf,orig_values,orig_labels,1)
            pause
            close(gcf)
        end
        t = toc;
        
        %% Determine TP/FP/FN status
        
        % start assuming it's neither false positive nor false negative
        false_negative = 0;
        false_positive = 0;
        
        if isempty(gdf)
            % false negative if no spike
            false_negative = 1;
        else    
            mid_file = size(values,1)/2; % middle index
            diff_from_zero = gdf(:,2) - mid_file;
            time_from_zero = diff_from_zero/fs; % convert index to time
            outside_allowable_time = abs(time_from_zero) > allowable_time_from_zero;
            n_false_positive = sum(outside_allowable_time);
            if n_false_positive > 0
                false_positive = 1;
            end
            if n_false_positive == length(gdf)
                % also false negative if all spikes detected were false
                % positive
                false_negative = 1;
            end
        end
        
  
        test.spike(s).false_negative = false_negative;
        test.spike(s).false_positive = false_positive;
        test.spike(s).n_false_positive = n_false_positive;
        test.spike(s).gdf = gdf;
        
        if do_save
            save([out_folder,name,'_test.mat'],'test')
        end
        
        
    end
end
