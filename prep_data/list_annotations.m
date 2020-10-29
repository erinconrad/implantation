function list_annotations

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));

%% Load pt file
pt = load([data_folder,'pt.mat']);
pt = pt.pt;


for p = 1:length(pt)
    
    fprintf('\n%s:\n',pt(p).name);
    
    yes_ann = 0;

for f = 1:length(pt(p).ieeg_names)
    if isfield(pt(p).filename(f),'ann') && ~isempty(pt(p).filename(f).ann)
        yes_ann = 1;
        for a = 1:length(pt(p).filename(f).ann)
            fprintf('%s\n',pt(p).filename(f).ann(a).name);
        end
    end
    
end

if yes_ann == 0
    fprintf('No annotations!\n');
end

end

end