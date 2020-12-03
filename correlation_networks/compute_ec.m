function v = compute_ec(A)

n = length(A);
if n < 1000
    [V,D] = eig(A);
else
    [V,D] = eigs(sparse(A));
end
[~,idx] = max(diag(D));
ec = abs(V(:,idx));
v = reshape(ec, length(ec), 1);


end