function shade_area_between_vectors(vecs,col_input)

% Find the long dimension
[a,b] = size(vecs);
if b == 2
    vecs = vecs';
elseif a ~=2
    error('what')
end

% Get vector length
len = size(vecs,2);

X = [1:len,fliplr(1:len)];
Y = [vecs(1,:),fliplr(vecs(2,:))];

f = fill(X,Y,'r');
set(f,'facealpha',0.4)
set(f,'edgecolor','none')
set(f,'facecolor',col_input)

end