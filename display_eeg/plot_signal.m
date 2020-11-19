function plot_signal(values,chLabels,display_time,spikes,fs,start_time,bad)
hold off
offset = 0;
ch_offsets = zeros(size(values,2),1);
ch_bl = zeros(size(values,2),1);

% Loop over channels
for ich = 1:size(values,2)
    if bad(ich) == 1
        plot(linspace(0,display_time,size(values,1)),values(:,ich)-offset,'k');
    else
        plot(linspace(0,display_time,size(values,1)),values(:,ich)-offset,'b');
    end
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
    
    value_sp = values(round(index),ch);
    
    if bad(ch) == 1
        plot(time,value_sp - offset_sp,'ko')
    else
        plot(time,value_sp - offset_sp,'bo')
    end
    title(sprintf('Start time %1.1f s',start_time));
    
end


end