function bad = rm_bad_chs(eeg,fs,chLabels)

nchs = size(eeg,2);
bad = zeros(nchs,1);
thresh = 5;

do_plot = 0;
if do_plot == 1
    figure
    set(gcf,'position',[1 608 1400 197]);
end

%% Get median and IQR across all channels
Y = prctile((eeg(:)).^2,90);


for d = 1:nchs%1:nchs
    data = eeg(:,d);
    data = data-mean(data);
    orig_power = (data.^2);

    
    very_high_power = sum(orig_power > thresh*Y)/length(orig_power); 
    
    if very_high_power > 1e-1 %&& sum(orig_power>1e6)/length(orig_power) > 1e-3
        bad(d) = 1;
    end
    
    %{
    %% Get high frequency signal
    %{
    alpha = 0.99;
    %hp = data(2:end) - alpha*data(1:end-1);
    hp = highpass(data,50,fs);
    hp_power = (hp.^2);
    hp_above_thresh = sum(hp_power>1e3)/length(orig_power);
    %}

    %% Get low frequency signal
    
    beta = 0.99;
    %lp = (1-beta)*data(2:end) + beta*data(1:end-1);
    %lp = lowpass(data,1e-5,fs);
    lp = filter([1-beta],[1,-beta],data);
    lp_power = (lp.^2);
    
    %% Get the fraction of the LF power above a threshold
   % lp_above_thresh = sum(lp_power>1e4)/length(lp_power);
    %}
    
    %}
    %% Plot
    %
    if do_plot == 1
        plot(orig_power)
        hold on
        %plot(lp_power)
        %plot(lp)
        plot(get(gca,'xlim'),[Y Y]);
        plot(get(gca,'xlim'),[Y Y]*thresh);
        legend({'Original'})
        
        title(sprintf('%s frac high power %1.1e',chLabels{d},...
           very_high_power))
        %}
        % title(sprintf('%s, frac above thresh: %1.1e',chLabels{d},above_thresh))
        pause
        hold off
    end
    %} 
    %{
    if hp_above_thresh > 1e-3 || orig_above_thresh > 1e-3
        bad(d) = 1;
    end
    %}
end



bad = logical(bad);


end