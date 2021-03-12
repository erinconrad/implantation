function assess_detector_performance(detector)

%% Locations
locations = implant_files;
pwname = locations.pwfile;
scripts_folder = [locations.script_folder];
results_folder = [locations.main_folder,'results/'];
addpath(genpath(scripts_folder));
test_folder = [results_folder,'testing/',detector,'/'];

listing = dir([test_folder,'*.mat']);

end