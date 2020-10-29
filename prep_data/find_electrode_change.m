function find_electrode_change

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/'];
results_folder = [locations.main_folder,'results/'];
out_folder = [results_folder,'spikes/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));

%% Load pt file
pt = load([data_folder,'pt.mat']);
pt = pt.pt;


for p = 1:length(pt)
    elec_change_files = [];
    
    if pt(p).reimplant == 1
        implant_text = 'reimplant';
    else
        implant_text = 'single implant';
    end

    fprintf('\n\n\n%s (%s), files with electrode changes are:\n',pt(p).name,implant_text);

    
    for f = 2:length(pt(p).ieeg_names)

        %% Compare the electrode names to those of the prior file
        old_elecs = pt(p).filename(f-1).chLabels;
        new_elecs = pt(p).filename(f).chLabels;
        same = isequal(old_elecs,new_elecs);

        if same ~= 1
            elec_change_files = [elec_change_files,f];
            
            fprintf('\n%d\n',f);
            fprintf('Unique old electrodes:\n');
            C = setdiff(old_elecs,new_elecs);
            for i = 1:length(C)
                fprintf('%s\n',C{i});
            end
            pt(p).filename(f).lost_elecs = C;
                    
            fprintf('\nUnique new electrodes:\n');
            C = setdiff(new_elecs,old_elecs);
            for i = 1:length(C)
                fprintf('%s\n',C{i});
            end
            pt(p).filename(f).added_elecs = C;
            
        else
            pt(p).filename(f).lost_elecs = [];
            pt(p).filename(f).added_elecs = [];
        
        end
        
    end
    
    pt(p).elec_change_files = elec_change_files;
    if isempty(elec_change_files) == 0 && pt(p).reimplant == 0
        pt(p).exclude.label = 1;
        pt(p).exclude.reason = 'Electrode changes but not reimplant patient';
    end

end

save([data_folder,'pt.mat'],'pt');

end