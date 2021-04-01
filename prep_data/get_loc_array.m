function out = get_loc_array(elecs,sys)

out = nan(length(elecs.locs),3);
for i = 1:size(out,1)
    if ~isempty(elecs.locs(i).system)
        out(i,:) = elecs.locs(i).system(sys).locs;
    end
    
end

end