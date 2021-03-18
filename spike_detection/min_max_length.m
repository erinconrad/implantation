function final_spikes = min_max_length(all_spikes,min_time,min_chs,max_chs)

final_spikes = [];

s = 1;
curr_seq = s;
last_time = all_spikes(s,1);

while s<size(all_spikes,1)
    new_time = all_spikes(s+1,1);
    
    if new_time - last_time < min_time
        curr_seq = [curr_seq;s+1]; % append it to the current sequence
    else
        % done with sequence, check if the length of sequence is
        % appropriate
        l = length(curr_seq);
        if l >= min_chs && l <= max_chs
            final_spikes = [final_spikes;all_spikes(curr_seq,:)];
        end
        
        % reset sequence
        curr_seq = s+1;
    end
    
    % increase the last time
    last_time = all_spikes(s+1,1);
    
    % increase the current spike
    s = s+1;
    
end

end