

function get_chosen_spikes(whichPts,tmul,absthresh,min_chs,overwrite)

%running through 9

%% General parameters
doing_test = 0;
%whichPts = [10 1 3 5 6 8 9 11]; % I believe these are the pts with all available data
add_clean_times = 0;
batch_time = 60;
pt_file = 'pt_w_elecs.mat';

%% Test parameters
if doing_test
    test_pt = 'HUP78_phaseII';
    do_plots = 1;
    test_time = 402536.90;
    test_label = [];%'LG59';%[];%'AST1';
    do_save = 0;
    overwrite = 1;
else
    do_save = 1;
    do_plots = 0;
end

%% Spike detector parameters
max_ch_pct = 50; % if spike > 50% of channels, throw away

display_time = 60;

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/data_files/'];
results_folder = [locations.main_folder,'results/'];
out_folder = [results_folder,'spikes/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));

%% Load pt file
pt = load([data_folder,pt_file]);
pt = pt.pt;

if exist(out_folder,'dir') == 0
    mkdir(out_folder)
end

if isempty(whichPts)
    whichPts = [10 1 3 5 6 8 9 11];
end

for p = whichPts

    pt_name = pt(p).name;
    if ~doing_test
        fname = sprintf('%s_spikes.mat',pt_name);
    end
    
    %% Add clean times to structure
    if add_clean_times == 1
        pt = add_clean_times_to_struct(pt);
        % If not, doing the randomly chosen times already there
    end
    
    %% Times to do
    pre_implant = pt(p).pre_times;
    post_implant = pt(p).post_times;
    all_times = [pre_implant,ones(size(pre_implant,1),1);...
        post_implant,2*ones(size(pre_implant,1),1)]; % 2 means post-implant
    
    %% Check for existing files
    clear spikes
    
    if overwrite == 0
        if exist([out_folder,fname],'file') ~= 0
            spikes = load([out_folder,fname]);
            spikes = spikes.spikes;


            fprintf('File already exists, loading and starting from last time.\n');
        else
            spikes.name = pt_name;
            spikes.times = all_times;
            spikes.time_index = 1;
            spikes.server_error_times = [];
            spikes.tmul = tmul;
            spikes.absthresh = absthresh;
        end
    else
        spikes.name = pt_name;
        spikes.times = all_times;
        spikes.time_index = 1;
        spikes.server_error_times = [];
        spikes.tmul = tmul;
        spikes.absthresh = absthresh;
    end
    
    if isfield(spikes,'spikes') == 0
        for i = 1:size(all_times,1)
            
            % start time, end time, file index
            spikes.spikes(i).times = [all_times(i,3) all_times(i,3)+all_times(i,4) all_times(i,2)];
            spikes.spikes(i).pre_or_post = all_times(i,5);
            spikes.spikes(i).spikes = [];
            spikes.spikes(i).start_time = all_times(i,3);
        end
    end
    
    n_times = size(all_times,1);
    curr_index = spikes.time_index;
    
    for i = curr_index:n_times

        if doing_test
            end_time = inf;
            start_time = test_time;
        else
            start_time = spikes.spikes(i).start_time;
            end_time = spikes.spikes(i).times(2);
        end
        
        %fprintf('\nDoing time %d  of %d \n',curr_index,n_times);

        
        while start_time < end_time
            tic
            if ~doing_test
                fprintf('\nDoing %1.1f of %1.1f s of %d of %d\n',start_time-spikes.spikes(i).times(1),...
                    spikes.spikes(i).times(2)-spikes.spikes(i).times(1),i,n_times);
            end
            
            %% Download data
            % Wrap it in a try catch loop to look for internal server
            % errors and move to the next second
            

            if doing_test
                data = get_eeg(test_pt,pwname,[start_time start_time+batch_time]);
            else
                data = get_eeg(pt(p).ieeg_names{spikes.spikes(i).times(3)},...
                        pwname,[start_time start_time+batch_time]);
            end
            %}
            %}
               
            %{
            try
                data = get_eeg(pt(p).ieeg_names{spikes.spikes(i).times(3)},...
                    pwname,[start_time start_time+batch_time]);
            catch ME
                if contains(ME.message,'An error response with status 500 (Internal Server Error)')
                    str=input('\nWacky server error, skipping this minute. Okay? (y/n)\n','s');
                    if strcmp(str,'y')
                        
                        % Add info about this minute to the file
                        spikes.server_error_times = [spikes.server_error_times;...
                            spikes.spikes(i).times(3),start_time,start_time+batch_time]; % whichfile, which times


                        % Move to next time
                        start_time = start_time+batch_time;
                        continue
                    else
                        error('Fix it');
                    end
                else
                    ME.message
                    error('Other error')
                end
            end
                    %}
            values = data.values;
            chLabels = data.chLabels(:,1);
            orig_labels = chLabels;
            chLabels = clean_labels(chLabels);
            new_orig_labels  = chLabels;
            
            if ~isequal(chLabels,orig_labels)
                fprintf('\nCleaned channel labels:\n');
                [orig_labels,chLabels]
            end
            
            chIndices = 1:size(values,2);
            fs = data.fs;
            
            %% Filters
            values = do_filters(values,fs,chLabels);
            
            orig_values = values;
            non_ekg_chs = get_non_ekg_chs(chLabels);
            %bad = zeros(length(chLabels),1);
            if 0
                values(:,~non_ekg_chs) = [];
                chLabels(~non_ekg_chs) = [];
                chIndices(~non_ekg_chs) = [];
            end
            
            

            
            
           
            
            %% Remove artifact heavy channels
            
            if 1
                bad = rm_bad_chs(values,fs,chLabels);
                fprintf('\nDesignated %d of %d channels as bad.\n',sum(bad),length(bad));
                bad(~non_ekg_chs) = 1;
                values(:,bad) = [];
                chLabels(bad) = [];
                chIndices(bad) = [];
            end

            %% Spike detection
            if doing_test && ~isempty(test_label)
                test_ch = strcmp(test_label,chLabels);
                %gdf = fspk2(values,tmul,absthresh,size(values,2),fs);
                out = detect_spikes(values,tmul,absthresh,fs,min_chs,max_ch_pct,test_ch);
            else
                %gdf = fspk2(values,tmul,absthresh,size(values,2),fs);
                out = detect_spikes(values,tmul,absthresh,fs,min_chs,max_ch_pct,[]);
            end
            
            %{
            max_chs = round(max_ch_pct/100*size(values,2));
            min_idx = min_time*fs;
            
            if min_ch_check
                if ~isempty(gdf)
                    gdf = min_max_length(gdf,min_idx,min_chs,max_chs);
                end
            end
            
            if ~isempty(gdf)
                out = [gdf(:,2),gdf(:,1)];
            else
                out = gdf;
            end
            %}

            if ~isempty(out)

                %% Spikes on EKG
                if 0
                    ekg_spikes = detect_spikes(orig_values(:,~non_ekg_chs),tmul,absthresh,fs,0,100,[]);
                    if ~isempty(ekg_spikes)
                    all_spikes = remove_ekg(out,ekg_spikes,fs);
                    out = all_spikes;
                    end
                end
                
                %% Adjust times of spikes
                indices = out(:,1);
                out = adjust_spike_times(out,start_time,fs);
                

                %% Re-derive original channels
                out = rederive_original_chs(chIndices,out,chLabels,new_orig_labels);
            else
                indices = [];
            end
            
            if do_plots
                plot_signal(orig_values,new_orig_labels,display_time,out,indices,fs,start_time,bad);
            end

            %% Add data to structure and save
            spikes.spikes(i).spikes = [spikes.spikes(i).spikes;out];
            spikes.spikes(i).start_time = start_time+batch_time;
            spikes.time_index = i;
            spikes.fs = fs;
            spikes.spikes(i).chLabels = chLabels;
            spikes.spikes(i).chLabels_orig = data.chLabels(:,1);
            if do_save == 1
                save([out_folder,fname],'spikes');
            end

            %% Move to next start time
            start_time = start_time+batch_time;
            t = toc;
            fprintf('Finished in %1.1f seconds. Detected %d spikes.\n',t,size(out,1));
            
        end
    end

end

    

end