function V = interp_centroids(C, F, P)
%INTERP_CENTROIDS  Piecewise-linear interpolation of centroid values F (n x m)
%   at query points P (k x 2) using a Delaunay triangulation of centroids C.
tri = delaunay(C(:,1), C(:,2));
if exist('OCTAVE_VERSION', 'builtin')
    ti = tsearch(C(:,1), C(:,2), tri, P(:,1), P(:,2));
    ok = ~isnan(ti);  bc = nan(size(P,1), 3);
    x1 = C(tri(ti(ok),1),:); x2 = C(tri(ti(ok),2),:); x3 = C(tri(ti(ok),3),:);
    D  = (x2(:,2)-x3(:,2)).*(x1(:,1)-x3(:,1)) + (x3(:,1)-x2(:,1)).*(x1(:,2)-x3(:,2));
    b1 = ((x2(:,2)-x3(:,2)).*(P(ok,1)-x3(:,1)) + (x3(:,1)-x2(:,1)).*(P(ok,2)-x3(:,2)))./D;
    b2 = ((x3(:,2)-x1(:,2)).*(P(ok,1)-x3(:,1)) + (x1(:,1)-x3(:,1)).*(P(ok,2)-x3(:,2)))./D;
    bc(ok,:) = [b1, b2, 1 - b1 - b2];
else
    TR = triangulation(tri, C);
    [ti, bc] = pointLocation(TR, P);
    ok = ~isnan(ti);
end
V = nan(size(P,1), size(F,2));
for j = 1:size(F,2)
    f = F(:,j);
    V(ok,j) = sum(bc(ok,:) .* f(tri(ti(ok),:)), 2);
end
end
