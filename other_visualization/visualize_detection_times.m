function visualize_detection_times(p)

%% Parameters
%p = 1;

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/data_files/'];

%% Load data file
pt = load([data_folder,'pt_w_elecs.mat']);
pt = pt.pt;

%% Plot the times
figure
plot(1:size(pt(p).pre_times,1),pt(p).pre_times(:,1),'bo');
hold on
plot(size(pt(p).pre_times,1)+1:size(pt(p).pre_times,1)+size(pt(p).post_times,1),...
    pt(p).post_times(:,1),'bo');

end