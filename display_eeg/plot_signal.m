function plot_signal(values,chLabels,display_time,spikes,fs,start_time)
hold off
offset = 0;
ch_offsets = zeros(size(values,2),1);
ch_bl = zeros(size(values,2),1);

% Loop over channels
for ich = 1:size(values,2)
    plot(linspace(0,display_time,size(values,1)),values(:,ich)-offset);
    ch_offsets(ich) = offset;
    ch_bl(ich) = -offset + median(values(:,ich));
    hold on
    text(display_time+0.05,ch_bl(ich),sprintf('%s',chLabels{ich}))
    if ich<size(values,2)
        offset = offset - (min(values(:,ich)) - max(values(:,ich+1)));
    end

end

for s = 1:size(spikes,1)
    index = spikes(s,1);
    
    % convert index to time
    time = index/fs;
    
    ch = spikes(s,2);
    offset_sp = ch_offsets(ch);
    
    value_sp = values(index,ch);
    
    plot(time,value_sp - offset_sp,'o')
    title(sprintf('Start time %1.1f s',start_time));
    
end


end