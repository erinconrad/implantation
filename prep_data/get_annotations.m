function get_annotations

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
    
    %if f == 4, error('look\n'); end
    
    %% Get annotations
    n_layers = length(session.data.annLayer);
    for ai = 1:n_layers
        a=session.data.annLayer(ai).getEvents(0);
        n_ann = length(a);
        for i = 1:n_ann
            event(i).start = a(i).start/(1e6);
            event(i).stop = a(i).stop/(1e6); % convert from microseconds
            event(i).type = a(i).type;
            event(i).description = a(i).description;
        end
        ann.event = event;
        ann.name = session.data.annLayer(ai).name;
        pt(p).filename(f).ann(ai) = ann;
    end
    
    session.delete;
    
end


end

%% Save the file
save([data_folder,'pt.mat'],'pt');

end