function wavelet_detector

name = 'HUP099_phaseII_D01';
time = 29706.32;
ch = 16;


%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/data_files/'];
results_folder = [locations.main_folder,'results/'];
out_folder = [results_folder,'spikes/'];
pwname = locations.pwfile;

data = get_eeg(name,pwname,[time time+15]);


values = data.values;
chLabels = data.chLabels(:,1);
chLabels = clean_labels(chLabels);

fs = data.fs;
            
%% Filters
new_values = do_filters(values,fs,chLabels);
non_ekg_chs = get_non_ekg_chs(chLabels);

%% Plot
if 1
figure
plot(values(:,ch));
hold on
plot(new_values(:,ch))
end

end