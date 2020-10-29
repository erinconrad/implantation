function get_file_duration

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
    
    for f = 1:length(pt(p).ieeg_names)
        
        %% Download data
        loginname = 'erinconr';
        session = IEEGSession(pt(p).ieeg_names{f}, loginname, pwname);    
        
        %% Get file length
        duration = session.data.rawChannels(1).get_tsdetails.getDuration/(1e6); %convert from microseconds
        
        pt(p).filename(f).duration = duration;
        
        session.delete;
        
    end
    
    
    
end

%% Save the file
save([data_folder,'pt.mat'],'pt');

end