function correlation_networks(overwrite,whichPts)

%% General parameters
%whichPts = [1 3 5 6 8 9 10 11]; % I believe these are the pts with all available data

pt_file = 'pt_w_elecs.mat';
nets_per_period = 10; % pick 10 random seconds per 30 minute period
net_time = 1; % 1 second of data to calculate network

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/data_files/'];
results_folder = [locations.main_folder,'results/'];
out_folder = [results_folder,'networks/'];

pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));

%% Load pt file
pt = load([data_folder,pt_file]);
pt = pt.pt;

if exist(out_folder,'dir') == 0
    mkdir(out_folder)
end

for p = whichPts
    pt_name = pt(p).name;
    fname = sprintf('%s_network.mat',pt_name);
    
    %% Times to do
    pre_implant = pt(p).pre_times;
    post_implant = pt(p).post_times;
    all_times = [pre_implant,ones(size(pre_implant,1),1);...
        post_implant,2*ones(size(pre_implant,1),1)]; % 2 means post-implant
    
    %% Check for existing files
    clear networks
    
    if overwrite == 0
        if exist([out_folder,fname],'file') ~= 0
            networks = load([out_folder,fname]);
            networks = networks.networks;


            fprintf('File already exists, loading and starting from last time.\n');
        else
            networks.name = pt_name;
            networks.times = all_times;
            networks.time_index = 1;
        end
    else
        networks.name = pt_name;
        networks.times = all_times;
        networks.time_index = 1;
    end
    
    if isfield(networks,'networks') == 0
        for i = 1:size(all_times,1)
            
            % start time, end time, file index
            networks.networks(i).times = [all_times(i,3) all_times(i,3)+all_times(i,4) all_times(i,2)];
            networks.networks(i).pre_or_post = all_times(i,5);
            networks.networks(i).networks = [];
            networks.networks(i).seconds = nan(nets_per_period,1);
            networks.networks(i).rand_index = 1;
        end
    end
    
    n_times = size(all_times,1);
    curr_index = networks.time_index;
    
    % Loop over the 30 minute time blocks
    for i = curr_index:n_times
        
        % Loop over the random indices within that 30 minute block
        for r = networks.networks(i).rand_index:nets_per_period
            
            fprintf('%s: Doing random second %d of %d of block %d of %d.\n',...
                pt_name,r,nets_per_period,i,n_times);
        
            %% Get a random second within the 30 minute block
            s = randi([round(all_times(i,3)) round(all_times(i,3)+all_times(i,4))]);
            
            %% Download data
            data = get_eeg(pt(p).ieeg_names{networks.networks(i).times(3)},...
                    pwname,[s s+net_time]);
                
            values = data.values;
            chLabels = data.chLabels(:,1);
            chIndices = 1:size(values,2);
            fs = data.fs;

            non_ekg_chs = get_non_ekg_chs(chLabels);
            values(:,~non_ekg_chs) = [];
            chLabels(~non_ekg_chs) = [];
            chIndices(~non_ekg_chs) = [];
            
            %% Filters
            values = do_filters(values,fs);

            %% Get Pearson correlation network
            adj = pearson_network(values);
            
            %% flatten the adjacency matrix (cuts size in half without losing information)
            adj = flatten_or_expand_adj(adj);
            
            %% Add to structure and save
            networks.networks(i).networks = [networks.networks(i).networks,adj];
            networks.networks(i).seconds(r) = s;
            networks.networks(i).rand_index = r;
            networks.networks(i).time_index = i;
            networks.fs = fs;
            networks.networks(i).chLabels = chLabels;
            save([out_folder,fname],'networks');

        end
    end
    
    
end

end