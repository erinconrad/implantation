function gdf = wavelet_detector(values,fs)

fb = [10 150];
tmul = 20;
width_idx = [250 500];

nchs = size(values,2);
nsamples = size(values,1);
total_time = nsamples/fs;
tm = linspace(0,total_time,nsamples);

gdf = [];

for ich = 1:nchs
    eeg = values(:,ich);
    
    % Get baseline
    bl = median(eeg);
    
    % get dev
    bl_dev = std(eeg);
    
    thresh = bl_dev*tmul;
    
    [cfs,f] = cwt(eeg,fs);
    
    if 1
    figure
    imagesc(tm,f,abs(cfs));
    end
    
    % sum the signal across the desired frequency band
    sig_freq = sum(abs(cfs(f>=fb(1) & f<=fb(2),:)),1);
    
    % low pass filter (to find peaks)
    lp = lowpass(sig_freq,1,fs);
    lp = lp';
    
    % Find peaks
    [p,t]=FindPeaks(lp);
    all_p = [p;t];
    all_p = [1;all_p;nsamples];
    [all_p] = sort(all_p);

    
    
    % Look for peaks that exceed an amplitude threshold
    big_p = find(abs(lp(all_p)-median(lp)) > thresh);
    
    if 0
        keep = zeros(length(big_p),1);

        % Loop through big peaks
        for i = 1:length(big_p)

            if big_p(i) == 1 || big_p(i) == nsamples
                continue;
            end

            % Look at surrounding values
            earlier = all_p(big_p(i)-1);
            later = all_p(big_p(i)+1);

            % see if they're an allowable time apart
            if later-earlier > width_idx(1) && later-earlier < width_idx(2)

                keep(i) = 1;
            end

        end

        big_p(keep==0) = [];
    end
    
    new_keep = ones(length(big_p),1);
    % If 2 adjacent ones, pick the bigger one
    for i = 1:length(big_p)-1
        if big_p(i+1) == big_p(i) + 1
            if all_p(big_p(i+1))>all_p(big_p(i))
                new_keep(i) = 0;
            else
                new_keep(i+1) = 0;
            end
        end
    end
    big_p(new_keep == 0) =[];
    
    
    spikes = all_p(big_p);
    
    if 0
        figure
        plot(eeg,'b');
        hold on
        plot(lp,'r');
        plot(xlim,[bl bl],'k');
        plot(xlim,[bl+thresh bl+thresh],'k--');
        plot(xlim,[bl-thresh bl-thresh],'k--');
        
        for i = 1:length(spikes)
            plot(spikes(i),eeg(spikes(i)),'o');
        end
    end
        
        
    spikes_with_ch = [repmat(ich,length(spikes),1),spikes];
    gdf = [gdf;spikes_with_ch];
    
end


end