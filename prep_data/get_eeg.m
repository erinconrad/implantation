function data = get_eeg(dataName,pwname,times)

% This is a tool to return information from a specified iEEG dataset


%% Unchanging parameters
loginname = 'erinconr';
n = 0;
session = IEEGSession(dataName, loginname, pwname);
fs = session.data.sampleRate;
channelLabels = session.data.channelLabels;

start_index = max(1,round(times(1)*fs));
end_index = round(times(2)*fs); % no way to know size of values ahead of time so I can't account for asking for data beyond end of file
values = session.data.getvalues([start_index:end_index],':');

data.values = values;
data.chLabels = channelLabels;
data.fs = fs;

session.delete;
clearvars -except data

end