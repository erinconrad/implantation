function non_ekg_chs = get_non_ekg_chs(chLabels)

non_ekg_chs = ones(length(chLabels),1);

for i = 1:length(chLabels)
    curr_label = chLabels{i};
    if contains(curr_label,'EKG') || contains(curr_label,'ekg')
        non_ekg_chs(i) = 0;
    end
    
    % remove RR channels too
    if contains(curr_label,'rate') || contains(curr_label,'rr') || contains(curr_label,'RR')
        non_ekg_chs(i) = 0;
    end
end


end