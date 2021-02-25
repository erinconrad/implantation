function values = do_filters(values,fs,chLabels)

%
%% Bipolar montage
for ch = 1:size(values,2)
    % Initialize it as nans
    out = nan(size(values,1),1);

    % Get electrode name
    label = chLabels{ch};

    % get the non numerical portion
    label_num_idx = regexp(label,'\d');
    label_non_num = label(1:label_num_idx-1);

    % get numerical portion
    label_num = str2num(label(label_num_idx:end));

    % see if there exists one higher
    label_num_higher = label_num + 1;
    higher_label = [label_non_num,sprintf('%d',label_num_higher)];
    if sum(strcmp(chLabels(:,1),higher_label)) > 0
        higher_ch = find(strcmp(chLabels(:,1),higher_label));
        out = values(:,ch)-values(:,higher_ch);
    else
        % allow it to remain nans
    end
    values(:,ch) = out;
end
%}

%
%% Notch filter
f = designfilt('bandstopiir','FilterOrder',2, ...
   'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
   'DesignMethod','butter','SampleRate',fs);
%fvtool(f)
for i = 1:size(values,2)
   values(isnan(values)) = 0;
   values(:,i) = filtfilt(f,values(:,i));   
end

%% High pass filter
f = designfilt('highpassiir','FilterOrder',4, ...
   'PassbandFrequency',0.5,'PassbandRipple',0.2, ...
   'SampleRate',fs);
%figure
for i = 1:size(values,2)
   % plot(values(:,i))
    %hold on
    values(:,i) = filtfilt(f,values(:,i));  
   % plot(values(:,i))
   % pause
   % hold off
end
%}

%% Common average reference
%values = values - mean(values,2);


end