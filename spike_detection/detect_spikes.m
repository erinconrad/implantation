function final_spikes = detect_spikes(eeg,tmul,absthresh,srate,min_chs,max_ch_pct)


% Check function input
if ~exist('tmul')
    error('no tmul\n')
end

if ~exist('absthresh')
    error('no absthresh\n')
end

% Initialize parameters
n_chans = size(eeg,2);
rate   = srate;
chan   = 1:n_chans;

spkdur = 220;                % spike duration must be less than this in ms
spkdur = spkdur*rate/1000;   % convert to points;
fr     = 40; % low pass filter for spikey component
lfr    = 7;  % low pass filter for slow wave component
aftdur = 70;
aftdur   = aftdur*rate/1000;   % convert to points;
spikedur = 10; % minimum spike duration in points
fn_fr  = 8; % high pass filter for spikey component

% Initialize things
all_spikes  = [];
allout      = [];
totalspikes = zeros(1, length(chan));
removed     = [];


% Iterate channels and detect spikes
for dd = 1:n_chans    
    
        data = eeg(:,dd);
        out = [];
        
        %% re-adjust the mean of the data to be zero (if there is a weird dc shift)
        data = data - mean(data);

     %   plot(data);
        %% Run the spike detector

        spikes   = [];

        % first look at the high frequency data for the 'spike' component
        fndata   = eegfilt(data, fn_fr, 'hp',srate); % high pass filter
        HFdata    = eegfilt(fndata, fr, 'lp',srate); % low pass filter


        lthresh = mean(abs(HFdata));  % this is the smallest the initial part of the spike can be
        thresh  = lthresh*tmul;     % this is the final threshold we want to impose
        sthresh = lthresh*tmul/3;   % this is the first run threshold


        [spp,spv] = FindPeaks(HFdata);

        idx      = find(diff(spp) <= spkdur);       % find the durations less than or equal to that of a spike
        startdx  = spp(idx);
        startdx1 = spp(idx+1);

        % check the amplitude of the waves of appropriate duration
        for i = 1:length(startdx)
            spkmintic = spv((spv > startdx(i) & spv < startdx1(i))); % find the valley that is between the two peaks
            if abs(HFdata(startdx1(i)) - HFdata(spkmintic)) > sthresh && HFdata(startdx(i)) - HFdata(spkmintic) > lthresh   % see if the peaks are big enough
                spikes(end+1,1) = spkmintic;                                  % add timestamp to the spike list
                spikes(end,2)   = (startdx1(i)-startdx(i))*1000/rate;         % add spike duration to list
                spikes(end,3)   = abs(HFdata(startdx1(i)) - HFdata(spkmintic));    % add spike amplitude to list
            end

        end


        % now have a list of spikes that have passed the 'spike' criterion.


        
        spikes(:,4) = 0;    %these are the durations in ms of the afterhyperpolarization waves
        spikes(:,5) = 0;    %these are the amplitudes in uV of the afterhyperpolarization waves

        % now have a list of sharp waves that have passed criterion

        % check for after hyperpolarization
        dellist = [];



        LFdata = eegfilt(fndata, lfr, 'lp',srate);
        [hyperp,hyperv] = FindPeaks(LFdata);   % use to find the afterhyper wave
        olda = 0;  % this is for checking for repetitive spike markings for the same afterhyperpolarization
        for i = 1:size(spikes,1)
            % find the duration and amplitude of the slow waves, use this with the
            % amplitude of the spike waves to determine if it is a spike or not


            a = hyperp(find(hyperp > spikes(i,1)));          % find the times of the slow wave peaks following the spike

            try  % this try is just to catch waves that are on the edge of the data, where we try to look past the edge
                if a(2)-a(1) < aftdur                        % too short duration, not a spike, delete these from the list
                    dellist(end+1) = i;
                else 
                    % might be a spike so get the amplitude of the slow wave
                    spikes(i,4) = (a(2)-a(1))*1000/rate;       % add duration of afhp to the list
                    b = hyperv(find(hyperv > a(1) & hyperv < a(2))); % this is the valley
                    spikes(i,5) = abs(LFdata(a(1)) - LFdata(b));  % this is the amplitude of the afhp
                    if a(1) == olda    
                        % if this has the same afterhyperpolarization peak as the prev
                            dellist(end+1) = i-1;           % spike then the prev spike should be deleted

                    end
                end
                olda = a(1);

            catch
                dellist(end+1) = i;  % spike too close to the edge of the data
            end


        end

        s = spikes;

        spikes(dellist,:) = [];

        tooshort = [];
        toosmall = [];
        toosharp = [];

        % now have all the info we need to decide if this thing is a spike or not.
        for i = 1:size(spikes, 1)  % for each spike
            if sum(spikes(i,[3 5])) > thresh && sum(spikes(i,[3 5])) > absthresh            % both parts together are bigger than thresh: so have some flexibility in relative sizes
                if spikes(i,2) > spikedur     % spike wave cannot be too sharp: then it is either too small or noise
                    out(end+1,1) = spikes(i,1);         % add timestamp of spike to output list
                else
                    toosharp(end+1) = spikes(i,1);
                end
            else
                toosmall(end+1) = spikes(i,1);
            end
        end

        totalspikes(dd) =  totalspikes(dd) + length(out);  % keep track of total number of spikes so far

        if ~isempty(out)
         %% Re-align spikes to peak of data
         timeToPeak = [-.1,.15]; %Only look 100 ms before and 150 ms after the currently defined peak
         idxToPeak = timeToPeak*srate;
         for i = 1:size(out,1)
            currIdx = out(i,1);
            idxToLook = max(1,round(currIdx+idxToPeak(1))):...
                    min(round(currIdx+idxToPeak(2)),length(HFdata));  
            snapshot = data(idxToLook);
            %snapshot = HFdata(idxToLook); % Look at the high frequency data (where the mean is substracted already)
            [~,I] = max(abs(snapshot)); % The peak is the maximum absolute value of this
            out(i,1) = out(i,1) + idxToPeak(1) + I;
         end
        end



        if ~isempty(out)
            %error('look\n');
            out(:,2) = dd;
        end

        out = unique(out,'rows');

       all_spikes = [all_spikes;out];

    if 1== 0 && dd == 89
        figure
        plot_times = 1:15*srate;
        plot(linspace(0,15,length(plot_times)),data(plot_times))
        hold on
        plot(linspace(0,15,length(plot_times)),HFdata(plot_times))
        hold on
        plot(linspace(0,15,length(plot_times)),fndata(plot_times))
        error('look\n');
    end
       
    % if dd == 7, error('look'); end
        
        
    

        
end

if isempty(all_spikes)
    final_spikes = [];
    return; 
end


% Remove any spikes that don't have co-occurrence across multiple channels
% within 100 ms, or if >80% of channels within 100 ms

% sort by time
all_spikes = sortrows(all_spikes);
min_time = 100*rate/1000;
max_chs = round(max_ch_pct*n_chans);

final_spikes = min_max_length(all_spikes,min_time,min_chs,max_chs);
  

end