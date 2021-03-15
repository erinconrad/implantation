function gdf=erin_simple(values,fs,tmul)

width = [20 200]*1e-3;
lpf = 20;


width_idx = width*fs;
nchs = size(values,2);
nsamples = size(values,1);
total_time = nsamples/fs;
tm = linspace(0,total_time,nsamples);

gdf = [];

for ich = 1:nchs
    eeg = values(:,ich);
    
    % Get baseline
    bl = median(eeg);
    eeg = eeg-bl; % remove baseline
    
    
    % low pass filter the signal (for the purpose of finding peaks)
    lp = eegfilt(eeg, lpf, 'lp',fs);
    lpp = lp.^2;
    
    % get dev
    bl_dev = std(lpp);
    thresh = (bl_dev)*tmul;
    
    % Find peaks
    [p,t]=FindPeaks(lpp);
    all_p = [p;t];
    all_p = [1;all_p;nsamples];
    [all_p] = sort(all_p);

    
    % Look for peaks that exceed an amplitude threshold
    big_p = find((lpp(all_p)) > thresh);
    
    keep = zeros(length(big_p),1);
    
    % Loop through big peaks
    for i = 1:length(big_p)
        
        if big_p(i) == 1 || big_p(i) == length(all_p)
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
    
    new_keep = ones(length(big_p),1);
    % If 2 adjacent ones, pick the bigger one
    for i = 1:length(big_p)-1
        if big_p(i+1) == big_p(i) + 1
            if lpp(all_p(big_p(i+1)))>lpp(all_p(big_p(i)))
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
        plot(lpp,'b');
        hold on
        plot(xlim,[median(lpp) median(lpp)],'k');
        plot(xlim,[median(lpp)+thresh median(lpp)+thresh],'k--');
        plot(xlim,[median(lpp)-thresh median(lpp)-thresh],'k--');
        
        for i = 1:length(spikes)
            plot(spikes(i),eeg(spikes(i)),'o');
        end
    end
        
        
    spikes_with_ch = [repmat(ich,length(spikes),1),spikes];
    gdf = [gdf;spikes_with_ch];
    
end


end