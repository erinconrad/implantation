%{
This function takes a time relative to the start of the EEG file and
returns an absolute time for the patient (using the EEG file durations)
%}

function total_time = convert_file_time_to_total_time(pt,p,file_time,which_file)
    % Add up file durations prior to the current file
    prior_file_durs = 0;
    for f = 1:which_file-1
        prior_file_durs = prior_file_durs + pt(p).filename(f).duration;
    end
    
    total_time = file_time + prior_file_durs;

end