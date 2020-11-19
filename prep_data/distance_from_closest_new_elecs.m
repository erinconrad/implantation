function dist = distance_from_closest_new_elecs(pt,p)

%% Get locs in one friendly array
loc_arr = zeros(length(pt(p).master_elecs.locs),3);
for i = 1:length(pt(p).master_elecs.locs)
    if isempty(pt(p).master_elecs.locs(i).system)
        loc_arr(i,:) = [nan nan nan];
        continue;
    end
    temp_loc = pt(p).master_elecs.locs(i).system(1).locs;
    loc_arr(i,:) = temp_loc;
end


%% Get locs of new elecs
new_elecs = pt(p).master_elecs.change == 1;
new_locs = loc_arr(new_elecs,:);

%% Get distance from all locs to closest new loc
dist = zeros(size(loc_arr,1),1);
for i = 1:size(loc_arr,1)
    if isnan(loc_arr(i,1))
        dist(i) = nan;
        continue
    end
    min_dist = inf;
    for j = 1:size(new_locs,1)
        curr_dist = vecnorm(loc_arr(i,:) - new_locs(j,:));
        if curr_dist < min_dist
            min_dist = curr_dist;
        end
    end
    dist(i) = min_dist;
end

end