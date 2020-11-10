function pt = add_clean_times_to_struct(pt)

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/'];
clean_times_file = [data_folder,'reimplantation patients.xlsx'];

%% Load the clean times files
clean_times = readtable(clean_times_file,'ReadVariableNames',0);

for p = 1:length(pt)
    
    pre_times = [];
    post_times = [];
    
    if isnan(clean_times(p,:).Var3), continue; end
    
    % Get pre times
    pre_times = [clean_times(p,:).Var3 clean_times(p,:).Var4 3600;...
        clean_times(p,:).Var5 clean_times(p,:).Var6 3600];
    
    % Get post times
    post_times = [clean_times(p,:).Var7 clean_times(p,:).Var8 3600;...
        clean_times(p,:).Var9 clean_times(p,:).Var10 3600];
    
    % Add absolute times (not just relative to file)
    pre_abs = zeros(2,1);
    post_abs = zeros(2,1);
    
    for i = 1:size(pre_times,1)
        pre_abs(i) = convert_file_time_to_total_time(pt,p,pre_times(i,2),pre_times(i,1));
    end
    
    for i = 1:size(post_times,1)
        post_abs(i) = convert_file_time_to_total_time(pt,p,post_times(i,2),post_times(i,1));
    end
    
    % Add absolute times to the array
    pre_times = [pre_abs,pre_times];
    post_times = [post_abs,post_times];
    
    % Replace current pre_times and post_times with this
    pt(p).pre_times = pre_times;
    pt(p).post_times = post_times;
    
end

end