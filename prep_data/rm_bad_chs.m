function bad = rm_bad_chs(eeg)

nchs = size(eeg,2);
bad = zeros(nchs,1);
max_amp = 1e3;
max_sum_over_power = 1e2*size(eeg,1)/7500;

%% Identify channels with too much high frequency power
for d = 1:nchs
    data = eeg(:,d);
    data = data-mean(data);
    
    %alpha = 0.995;
    %lp = filter([1-alpha],[1,-alpha],data);
    alpha = 0.99;
    hp = data(2:end) - alpha*data(1:end-1);
    
    all_power = sum(data.^2);
    hp_power = sum(hp.^2);
    power_ratio = hp_power/all_power;
    
    if power_ratio > 0.4
        bad(d) = 1;
    end
    
    %{
    plot(data)
    hold on
    plot(hp)
    title(sprintf('Ratio: %1.2f',power_ratio))
    pause
    hold off
    %} 
end

%% Identify channels with too high an amplitude
for d = 1:nchs
    data = eeg(:,d);
    data = data-mean(data);
    over_power = sum(abs(data) > max_amp);
    
    %{
    plot(data)
    title(sprintf('Sum over power: %1.2f, max %1.2f',over_power,max_sum_over_power))
    pause
    hold off
    %}
    
    if over_power > max_sum_over_power
        bad(d) = 1;
    end
    
end

bad = logical(bad);


end