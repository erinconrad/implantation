function times_for_analysis

%{
The goal of this file is to pick random times pre- and post-reimplant for
which I will do subsequent analyses. I will pick random chunks of time
before and after the reimplantation, and then confirm that they are not too
close to:
- clinical events
- the start or end of a file
- other times

I may then do either manual or automatic analysis to decide if the times
are too artifact heavy.

STILL NEED TO GET SEIZURE TIMES
%}

%% Parameters
n_chunks = 50; % how many pre-reimplant and post-reimplant chunks?
chunk_duration = 1800; % how long should each chunk be?
dead_time = 1e4; % ignore the first 10,000 seconds at the start and end of each file
min_distance = 1800; % this is how far away different chunks should be from each other and from events

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/data_files/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));

%% Load pt file
pt = load([data_folder,'pt_w_elecs.mat']);
pt = pt.pt;

all_reimplant_times = [];

%% Loop through patients
for p = 1:length(pt)
    
    %% Skip the patient if exclude  == 1 or if multiple electrode change files
    if length(pt(p).elec_change_files) > 1
        continue;
    end
    
    if ~isempty(pt(p).exclude) && pt(p).exclude.label == 1
        continue;
    end
    
    %% Get total duration and times of file change and implantation time
    file_change_times = 0;
    duration = 0;
    for f = 1:length(pt(p).filename)
        if f == pt(p).elec_change_files
            reimplant_time = duration; % the duration up to this file is the reimplant time
            all_reimplant_times = [all_reimplant_times; reimplant_time];
            
        end
        duration = duration + pt(p).filename(f).duration;
        file_change_times = [file_change_times;duration];
        
    end
    
    if pt(p).reimplant == 0
        reimplant_time = median(all_reimplant_times);
    end
    
    %% Define initial exclusion times
    exclusion = 0;
    
    % Exclude peri file start and end
    for i = 1:length(file_change_times)
        exclusion = [exclusion;...
            file_change_times(i) - dead_time;...
            file_change_times(i) + dead_time];
    end
    
    %% Exclude time surrounding seizures
    sz_times = pt(p).sz_times;
    new_sz_times = sz_times;
    for t = 1:size(sz_times,1)
        file_time = sz_times(t,1);
        which_file = sz_times(t,2);
        
        % Convert to overall times
        total_time = convert_file_time_to_total_time(pt,p,file_time,which_file);
        new_sz_times(t,3) = total_time;
    end
    
    pt(p).sz_times = new_sz_times;
    
    % Exclude these times and one hour surrounding
    for i = 1:size(new_sz_times,1)
        exclusion = [exclusion;...
            new_sz_times(i,3) - min_distance;...
            new_sz_times(i,3) + min_distance];
    end
    
    %% Start building times
    for s = 1:2 % pre- vs post- reimplant
        all_time = [];
        
        curr_exclusion = exclusion;
        
        if s == 1
            allowable_time = [0 reimplant_time];
        else
            allowable_time = [reimplant_time duration];
        end
            
        while 1

            % Pick a random time (in seconds) in the allowable time
            candidate_time = randi(round(allowable_time));
            
            % See if it is too close to an exclusion time
            time_to_exclusion = abs(candidate_time-exclusion);
            if any(time_to_exclusion < min_distance) 
                continue; % do a new time
            else
                
                % if not too close to any exclusion time, add it. Also add
                % the filenumber and the time within the file
                diff_from_file_change = file_change_times - candidate_time;
                pos_indices = find(diff_from_file_change>0);
                if isempty(pos_indices)
                    file_idx = length(pt(p).filename);
                else
                    file_idx = pos_indices(1)-1; % first file in which candidate time is after file start time
                end
                
                duration_to_file = file_change_times(file_idx);
                duration_in_file = candidate_time - duration_to_file;
                all_time = [all_time;candidate_time, file_idx, duration_in_file, chunk_duration];
                
                % also add it to exclusion times
                curr_exclusion = [curr_exclusion;...
                    candidate_time;...
                    candidate_time + chunk_duration]; % Need to also add the end time to the exclusion times
                
                % See if I have enough times, and break if I do
                if length(all_time) == n_chunks
                    break
                end
                
                
            end

        end
        
        % Save the times
        if s == 1
            pre_times = all_time;
            pt(p).pre_times = sortrows(pre_times);
        else
            post_times = all_time;
            pt(p).post_times = sortrows(post_times);
        end
    end
    
end

%% Histogram of times
all_reimplant = [];
all_noreimplant = [];
for p = 1:length(pt)
    
    %% Skip the patient if exclude  == 1 or if multiple electrode change files
    if length(pt(p).elec_change_files) > 1
        continue;
    end
    
    if ~isempty(pt(p).exclude) && pt(p).exclude.label == 1
        continue;
    end
    
    if pt(p).reimplant == 1
        all_reimplant = [all_reimplant;pt(p).pre_times(:,1),pt(p).post_times(:,1)];
    else
        all_noreimplant = [all_noreimplant;pt(p).pre_times(:,1),pt(p).post_times(:,1)];
    end
end

figure
subplot(2,1,1)
histogram(all_reimplant(:,1),20)
hold on
histogram(all_noreimplant(:,1),20)
title('Pre reimplant')

subplot(2,1,2)
histogram(all_reimplant(:,2),20)
hold on
histogram(all_noreimplant(:,2),20)
title('Post reimplant')

save([data_folder,'pt_w_elecs.mat'],'pt')
end