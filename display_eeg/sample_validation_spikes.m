function sample_validation_spikes(all_p)

%% General parameters

n_sp_plot = 5;
n_per_fig = 5;
surround = 7.5;


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

if isempty(all_p)
    listing = dir([spike_folder,'*.mat']);
    for i = 1:length(listing)
        C = listing(i).name;
        temp_name = strsplit(C,'_');
        temp_name = temp_name{1};
        for j = 1:length(pt)
            pt_name = pt(j).name;
            if strcmp(temp_name,pt_name)
                all_p = [all_p,j];
                break
            end
        end
    end
end

for p = all_p
    pt_name = pt(p).name;
    out_folder = [results_folder,'validation/',pt_name,'/'];
    if exist(out_folder,'dir') == 0, mkdir(out_folder); end

    %% Load spike file
    spikes = load([spike_folder,sprintf('%s_spikes.mat',pt_name)]);
    spikes = spikes.spikes;
    %nspikes = size(spikes.spikes,1);

    %% concatenate all spikes into one long thing
    all_spikes = [];
    for s = 1:length(spikes.spikes)
        if isempty(spikes.spikes(s).spikes)
            continue
        end

        all_spikes = [all_spikes;...
            spikes.spikes(s).spikes,repmat(spikes.spikes(s).times(3),...
            size(spikes.spikes(s).spikes,1),1),repmat(s,...
            size(spikes.spikes(s).spikes,1),1)];
    end

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

        
        
        
        %% Randomly pick spike
        %{
        while 1
            ind = randi(length(spikes.spikes));
            if ~isempty(spikes.spikes(ind).spikes)
                break
            end
        end
        %}
        %sp = randi(size(spikes.spikes(ind).spikes,1));
        sp = randi(size(all_spikes,1));

        %% Get info about the spike
        %{
        curr_spike = spikes.spikes(ind).spikes(sp,:);
        f = spikes.spikes(ind).times(3);
        sp_time = curr_spike(1);
        sp_ch = curr_spike(2);
        %}
        f = all_spikes(sp,3);
        sp_time = all_spikes(sp,1);
        sp_ch = all_spikes(sp,2);
        ind = all_spikes(sp,4);

        %% Get the EEG data
        data = get_eeg(pt(p).ieeg_names{f},pwname,[sp_time-surround sp_time+surround]);
        values = data.values;
        chLabels = data.chLabels(:,1);
        chIndices = 1:size(values,2);
        fs = data.fs;

        sp_index = surround*fs;
        
     %  if ~isequal(chLabels,spikes.spikes(ind).chLabels), error('what'); end

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

end