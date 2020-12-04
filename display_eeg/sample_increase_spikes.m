function sample_increase_spikes(all_p)

%% General parameters
n_sp_plot = 20;
n_per_fig = 10;
surround = 7.5;
min_sp = 10;
n_std = 2;

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/data_files/'];
results_folder = [locations.main_folder,'results/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));
spike_folder = [results_folder,'spikes/'];


%% Load pt file
pt = load([data_folder,'pt_w_elecs.mat']);
pt = pt.pt;

for p = all_p
    pt_name = pt(p).name;
    out_folder = [results_folder,'validation-increase/',pt_name,'/'];
    if exist(out_folder,'dir') == 0, mkdir(out_folder); end

    %% Load spike file
    spikes = load([spike_folder,sprintf('%s_spikes.mat',pt_name)]);
    spikes = spikes.spikes;
    %nspikes = size(spikes.spikes,1);

    %% Make master list of electrodes
    all_elecs = pt(p).master_elecs;
    new_labels = all_elecs.master_labels;
    
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
    
    %% Compare spike counts
    num_pre = size(pt(p).pre_times,1);
    pre = sum(all_counts(:,1:num_pre),2);
    post = sum(all_counts(:,num_pre+1:end),2);
    rel_change = (post-pre)./pre;
    
    %% Get channels to ignore
    % Ignore EKG channels
    non_ekg_chs = get_non_ekg_chs(pt(p).master_elecs.master_labels);
    ekg_chs = logical(~non_ekg_chs);

    % Ignore channels for which number of spikes is less than minimum
    few_spikes = logical(pre+post < min_sp);

    % Ignore channels that are not always there
    changing_elecs = logical(all_elecs.change ~= 0);
    % Combine things I'm ignoring
    ignore_elecs = few_spikes | changing_elecs | ekg_chs;

    %% Find those electrodes with a substantial increase in spike rate
    min_rel_change = mean(rel_change(~ignore_elecs)) + n_std*std(rel_change(~ignore_elecs));
    elec_inc = find(rel_change > min_rel_change & ~ignore_elecs);

    
    
    
    
    which_plot = 0;
    for i = 1:n_sp_plot

        b = mod(i,n_per_fig);
        if b == 1
            figure
            set(gcf,'position',[0 0 1400 800])
            [ha,~] = tight_subplot(n_per_fig,1,[0.02 0.02],[0.05 0.05],[0.02 0.02]);
        elseif b == 0
            b = n_per_fig; 
        end
        
        %% Retrieve only the spikes from these channels
        while 1
            ind = randi(length(spikes.spikes));
            new_spikes = spikes.spikes(ind).new_spikes;
            spikes_on_inc_channels = ismember(new_spikes(:,2),elec_inc);
            if ~isempty(spikes_on_inc_channels)
                break
            end
        end
        curr_spikes = new_spikes(spikes_on_inc_channels,:);

        sp = randi(size(curr_spikes,1));
        
        
        %% Get info about the spike
        curr_spike = curr_spikes(sp,:);
        f = spikes.spikes(ind).times(3);
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
        axes(ha(b))
        plot(linspace(0,surround*2,size(values,1)),values(:,sp_ch),'linewidth',2);
        hold on
        plot(surround,values(round(sp_index),sp_ch),'o','markersize',10)
        title(sprintf('Spike %d %1.1f s %s index %d file %d',sp,sp_time,chLabels{sp_ch},ind,f),'fontsize',10)
        if b ~= n_per_fig
            xticklabels([])
        end
        yticklabels([])
        set(gca,'fontsize',10)

        if b == n_per_fig
            xlabel('Time (s)')
            which_plot = which_plot + 1;
            print([out_folder,sprintf('spikes_%d',which_plot)],'-depsc');
            close(gcf)
        end
        
        
    end
    
end