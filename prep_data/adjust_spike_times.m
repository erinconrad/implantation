function out = adjust_spike_times(out,start_time,fs)
    spike_times = out(:,1);
    new_times = spike_times/fs+start_time; % convert from index to time in s and add start time
    out(:,1) = new_times;

end