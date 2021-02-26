function wavelet_detector(values,fs)

freq_band = [10 150];
tmul = 15;

nchs = size(values,2);
nsamples = size(values,1);
total_time = nsamples/fs;
tm = linspace(0,total_time,nsamples);

for ich = 1:nchs
    eeg = values(:,ich);
    
    % Get baseline
    bl = median(eeg);
    
    % get dev
    bl_dev = std(eeg);
    
    thresh = bl_dev*tmul;
    
    [cfs,f] = cwt(eeg,fs);
    
    if 0
    figure
    imagesc(tm,f,abs(cfs));
    end
    
    % sum the signal across the desired frequency band
    sig_freq = sum(abs(cfs(f>=freq_band(1) & f<=freq_band(2),:)),1);
    
    % low pass filter (to find peaks)
    y = lowpass(sig_freq,1,fs);
    
    if 0
        figure
        plot(eeg,'b');
        hold on
        plot(xlim,[bl bl],'k');
        plot(xlim,[bl+thresh bl+thresh],'k--');
        plot(xlim,[bl-thresh bl-thresh],'k--');
        plot(sig_freq)
    end
        
        
    
    
end


end