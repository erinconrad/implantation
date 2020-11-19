function pt = not_really_removed(pt)

for p = 1:length(pt)
    
    if ~isstruct(pt(p).master_elecs), continue; end
    
    %% Denote ekg
    non_ekg_chs = get_non_ekg_chs(pt(p).master_elecs.master_labels);
    ekg_chs = logical(~non_ekg_chs);
    pt(p).master_elecs.ekg_chs = ekg_chs;
    
    if p == 3
        not_new = {'RO3','RO4'};
    elseif p == 8
        not_new = {'LJ1','LJ2','LJ3','LJ4','LJ5','LJ6','LJ7','LJ8',...
            'RE1','RE2','RE3','RE4','RE5','RE6','RE7','RE8',...
            'RF1','RF2','RF3','RF4','RF5','RF6','RF7','RF8'};
    else
        continue
    end
    
    for e = 1:length(pt(p).master_elecs.change)
        if ismember(pt(p).master_elecs.master_labels{e},not_new)
            pt(p).master_elecs.change(e) = 3;
        end
    end
    
    
    
end

end