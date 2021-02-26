function easy_plot(values,chLabels,times,which_chs,spikes,orig_values,orig_labels,show_bad)

if isempty(which_chs)
    if show_bad == 1
        values = orig_values;
        reduced_labels = chLabels;
        chLabels = orig_labels;
    else
        reduced_labels = chLabels;
    end
    which_chs = 1:size(values,2);
elseif iscell(which_chs)
    which_chs_out = zeros(length(which_chs),1);
    for i = 1:length(which_chs)
        which_chs_out(i) = find(strcmp(which_chs{i},chLabels));
    end
    which_chs = which_chs_out;
end
if size(which_chs,1) > size(which_chs,2)
    which_chs = which_chs';
end

figure
set(gcf,'position',[400  800  500 100*length(which_chs)])
offset = 0;
ch_offsets = zeros(length(which_chs),1);
ch_bl = zeros(length(which_chs),1);

ch_count = 0;
for ich = which_chs
    ch_count = ch_count + 1;
    curr_label = chLabels{ich};
    found_curr = 0;
    for j = 1:length(reduced_labels)
        if strcmp(curr_label,reduced_labels{j})
            found_curr = 1;
        end
    end
    if found_curr == 1
        plot(linspace(times(1),times(2),size(values,1)),values(:,ich)+offset,'k');
    else
        plot(linspace(times(1),times(2),size(values,1)),values(:,ich)+offset,'r');
    end
    ch_offsets(ch_count) = offset;
    ch_bl(ch_count) = offset + median(values(:,ich));
    hold on
    text(times(2)+0.05,ch_bl(ch_count),sprintf('%s',chLabels{ich}))
       
    % Plot spikes
    if ~isempty(spikes)
        which_spikes = find(spikes(:,1) == ich);
        for s = 1:length(which_spikes)
            sp_index = spikes(which_spikes(s),2);
            sp_time = convert_index_to_time(sp_index,times(1),times(2),size(values,1));
            sp_amp = values(sp_index,ich)+offset;
            plot(sp_time,sp_amp,'bo','markersize',10)
        end
    end
    
    if ich<size(values,2)
        offset = offset + max(values(:,ich)) - min(values(:,ich+1));
    end 
end


xlim([times(1),times(2)]);
        


end