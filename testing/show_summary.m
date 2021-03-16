%% Locations
locations = implant_files;
scripts_folder = [locations.script_folder];
results_folder = [locations.main_folder,'results/'];
addpath(genpath(scripts_folder));
summary_folder = [results_folder,'testing/'];

%% Load summary file
T = readtable([summary_folder,'summary.csv']);

%% Display summary file
T