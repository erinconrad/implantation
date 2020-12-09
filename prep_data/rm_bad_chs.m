function bad = rm_bad_chs(eeg,fs,chLabels)

nchs = size(eeg,2);
bad = zeros(nchs,1);
thresh = 5;

max_amp = 1e3;
max_sum_over_power = 1e2*size(eeg,1)/7500;

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

    
    %% HF power check
    alpha = 0.99;
    hp = data(2:end) - alpha*data(1:end-1);
    
    all_power = sum(data.^2);
    hp_power = sum(hp.^2);
    power_ratio = hp_power/all_power;
    
    if power_ratio > 0.4
        bad(d) = 1;
    end
    
    %% Relative overall power check
    very_high_power = sum(orig_power > thresh*Y)/length(orig_power); 
    
    if very_high_power > 1e-1 %&& sum(orig_power>1e6)/length(orig_power) > 1e-3
        bad(d) = 1;
    end
    
    %% Absolute overall power check
    over_power = sum(abs(data) > max_amp);
    if over_power > max_sum_over_power
        bad(d) = 1;
    end
    
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