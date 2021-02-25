function easy_plot(values,chLabels,times,which_chs)

if isempty(which_chs)
    which_chs = 1:size(values,2);
elseif iscell(which_chs)
    which_chs_out = zeros(length(which_chs),1);
    for i = 1:length(which_chs)
        which_chs_out(i) = find(strcmp(which_chs{i},chLabels));
    end
    which_chs = which_chs_out;
end

figure
set(gcf,'position',[1  194  500 100*length(which_chs)])
offset = 0;
ch_offsets = zeros(length(which_chs),1);
ch_bl = zeros(length(which_chs),1);

ch_count = 0;
for ich = which_chs'
    ch_count = ch_count + 1;
    plot(linspace(times(1),times(2),size(values,1)),values(:,ich)+offset);
    ch_offsets(ch_count) = offset;
    ch_bl(ch_count) = offset + median(values(:,ich));
    hold on
    text(times(2)+0.05,ch_bl(ch_count),sprintf('%s',chLabels{ich}))
    if ich<size(values,2)
        offset = offset + max(values(:,ich)) - min(values(:,ich+1));
    end
end

xlim([times(1),times(2)]);
        


end