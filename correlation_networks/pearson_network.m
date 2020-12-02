function adj = pearson_network(values)

nchs = size(values,2);
adj = zeros(nchs,nchs);

for i = 1:nchs
    for j = 1:i-1
        c = abs(corr(values(:,i),values(:,j))); % absolute value of Pearson correlation
        adj(i,j) = c;
        adj(j,i) = c;
    end
end


end