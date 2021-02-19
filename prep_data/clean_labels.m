function out_labels = clean_labels(chLabels)

out_labels = chLabels;

for ich = 1:length(chLabels)
    label = chLabels{ich};

    %% Remove leading zero
    % get the non numerical portion
    label_num_idx = regexp(label,'\d');
    if isempty(label_num_idx), continue; end

    label_non_num = label(1:label_num_idx-1);
    
    label_num = label(label_num_idx:end);
    
    % Remove leading zero
    if strcmp(label_num(1),'0')
        label_num(1) = [];
    end
    
    label = [label_non_num,label_num];
    
    %% Remove 'EEG '
    eeg_text = 'EEG ';
    if contains(label,eeg_text)
        eeg_pos = regexp(label,eeg_text);
        label(eeg_pos:eeg_pos+length(eeg_text)-1) = [];
    end
    
    %% Remove '-Ref'
    ref_text = '-Ref';
    if contains(label,ref_text)
        ref_pos = regexp(label,ref_text);
        label(ref_pos:ref_pos+length(ref_text)-1) = [];
    end
    
    %% Remove spaces
    if contains(label,' ')
        space_pos = regexp(label,' ');
        label(space_pos) = [];
    end
    
    out_labels{ich} = label;
end

end