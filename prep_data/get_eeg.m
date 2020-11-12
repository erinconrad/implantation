function data = get_eeg(dataName,pwname,times)

% This is a tool to return information from a specified iEEG dataset


%% Unchanging parameters
loginname = 'erinconr';
session = IEEGSession(dataName, loginname, pwname);
fs = session.data.sampleRate;
channelLabels = session.data.channelLabels;

start_index = max(1,round(times(1)*fs));
end_index = round(times(2)*fs); 

%values = session.data.getvalues([start_index:end_index],':');

% Break the number of channels in half to avoid wacky server errors

nchs = size(channelLabels,1);
%error('look');
values1 = session.data.getvalues([start_index:end_index],1:floor(nchs/2));
values2 = session.data.getvalues([start_index:end_index],floor(nchs/2)+1:nchs);
values = [values1,values2];
%}

data.values = values;
data.chLabels = channelLabels;
data.fs = fs;

session.delete;
clearvars -except data

end