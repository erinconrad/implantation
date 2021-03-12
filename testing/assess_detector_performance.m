function out = assess_detector_performance(detector,tmul,absthresh)

%% Locations
locations = implant_files;
scripts_folder = [locations.script_folder];
results_folder = [locations.main_folder,'results/'];
addpath(genpath(scripts_folder));
test_folder = [results_folder,'testing/',detector,'/'];

listing = dir([test_folder,'*.mat']);

summary = zeros(length(listing),3);
all_names = cell(length(listing),1);

for i = 1:length(listing)
    fname = listing(i).name;
    
    
    % Load the file
    test = load([test_folder,fname]);
    test = test.test;
    all_names{i} = test.name;
    
    n_spikes = length(test.spike);
    n_fn = 0;
    n_fp = 0;
    for s = 1:n_spikes
        if test.spike(s).false_negative == 1
            n_fn = n_fn + 1;
        end
        
        if test.spike(s).false_positive == 1
            n_fp = n_fp + 1;
        end

    end
    
    summary(i,:) = [n_spikes,n_fn,n_fp];
end

table(all_names,summary(:,1),summary(:,2),summary(:,3),...
    'VariableNames',{'Patient','Spikes','FalseNegatives','FalsePositive'})

%% Get summary stats
fprintf('\n%s detector, tmul = %1.1f, absthresh = %1.1f\n',detector,tmul,absthresh);

fprintf('\nThe rate of false positives was M = %1.1f%% (range %1.1f%%-%1.1f%%)\n',...
    mean(summary(:,3)./summary(:,1))*100,...
    min(summary(:,3)./summary(:,1))*100,max(summary(:,3)./summary(:,1))*100);

fprintf('\nThe rate of false negatives was M = %1.1f%% (range %1.1f%%-%1.1f%%)\n',...
    mean(summary(:,2)./summary(:,1))*100,...
    min(summary(:,2)./summary(:,1))*100,max(summary(:,2)./summary(:,1))*100);

mean_fp = mean(summary(:,3)./summary(:,1))*100;
mean_fn = mean(summary(:,2)./summary(:,1))*100;

out.fp = mean_fp;
out.fn = mean_fn;

end