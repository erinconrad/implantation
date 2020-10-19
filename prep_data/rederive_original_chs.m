function out = rederive_original_chs(chIndices,out,chLabels,oldLabels)
    ch_new = out(:,2);
    
    original_channels = chIndices(ch_new);
    out = [out(:,1),original_channels'];
    
    % Double check
    newLabels = chLabels(ch_new);
    oldLabels = oldLabels(original_channels);
    
    if ~isequal(newLabels,oldLabels), error; end
    
end