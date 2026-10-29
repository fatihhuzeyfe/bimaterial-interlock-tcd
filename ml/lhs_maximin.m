function U = lhs_maximin(n, d, ntry)
%LHS_MAXIMIN  Latin hypercube sample on [0,1]^d (best of NTRY by maximin distance).
%   Implemented without toolboxes so that the design is reproducible everywhere.
best = -inf; U = [];
for t = 1:ntry
    X = zeros(n, d);
    for j = 1:d, X(:,j) = (randperm(n).' - rand(n,1))/n; end
    D = inf;
    for i = 1:n-1
        D = min(D, min(sqrt(sum((X(i+1:end,:) - X(i,:)).^2, 2))));
    end
    if D > best, best = D; U = X; end
end
end
