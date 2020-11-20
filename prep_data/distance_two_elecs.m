function dist = distance_two_elecs(pt,p,label1,label2)

%% Find indices
for e = 1:length(pt(p).master_elecs.master_labels)
    if strcmp(label1,pt(p).master_elecs.master_labels{e})
        ind1 = e;
    elseif strcmp(label2,pt(p).master_elecs.master_labels{e})
        ind2 = e;
    end
end

%% Get distance
dist = vecnorm(pt(p).master_elecs.locs(ind1).system(1).locs - ...
    pt(p).master_elecs.locs(ind2).system(1).locs);

end