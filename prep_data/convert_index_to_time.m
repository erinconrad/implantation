function out_time = convert_index_to_time(index,first_time,last_time,sample_length)

out_time = index/sample_length*(last_time-first_time) + first_time;

end