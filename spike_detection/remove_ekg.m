function all_spikes = remove_ekg(all_spikes,ekg_spikes,fs)

%% Remove spikes close to EKG spikes
to_remove_ekg = zeros(size(all_spikes,1),1);

%loop over spikes

for s = 1:size(all_spikes,1)

    % Is there an ekg spike within 50 ms?
    if any(abs(all_spikes(s,1)/fs - ekg_spikes(:,1)/fs) < 0.020)
        to_remove_ekg(s) = 1;
    end

end

all_spikes(logical(to_remove_ekg),:) = [];

end
        
