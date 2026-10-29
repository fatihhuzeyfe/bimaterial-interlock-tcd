function [X, Y, V] = field_contour(ax, C, dom, val, P, w, yl, levels, nx)
%FIELD_CONTOUR  Smooth, banded (vector) contour map of an element field in a bi-material model.
%   The element values are interpolated separately in each constituent onto a fine regular
%   grid, so that the discontinuity of the stresses across the interface is preserved, and
%   drawn with CONTOURF. Compared with element-wise patches, the band boundaries are smooth
%   and the figure consists of few vector objects (clean in EPS/PDF and CorelDRAW).
%   C: element centroids, dom: constituent (1 = substrate, 2 = top), val: element values,
%   P: interface polyline (same coordinates as C), w/yl: plot window, levels: band limits.
if nargin < 9, nx = 700; end
ny = max(2, round(nx*diff(yl)/diff(w)));
[X, Y] = meshgrid(linspace(w(1), w(2), nx), linspace(yl(1), yl(2), ny));
big = max(abs([yl, w])) + 1e3;
top = inpolygon(X, Y, [P(:,1); P(end,1); P(1,1)], [P(:,2); big; big]);
mx = 0.15*diff(w); my = 0.15*diff(yl);
V = nan(size(X));
for d = 1:2
    sd = dom == d & C(:,1) > w(1) - mx & C(:,1) < w(2) + mx & C(:,2) > yl(1) - my & C(:,2) < yl(2) + my;
    msk = top; if d == 1, msk = ~top; end
    if any(msk(:)) && nnz(sd) > 3
        V(msk) = interp_fill(C(sd,:), val(sd), [X(msk) Y(msk)]);
    end
end
r = levels(end) - levels(1);
Vc = min(max(V, levels(1) + 1e-6*r), levels(end) - 1e-6*r);     % keep out-of-range values in the end bands
contourf(ax, X, Y, Vc, levels, 'LineColor', 'none');
caxis(ax, [levels(1) levels(end)]);
end

function v = interp_fill(C, f, Q)
% linear interpolation with nearest-neighbour extrapolation near the domain boundaries
if exist('scatteredInterpolant', 'file') || exist('scatteredInterpolant', 'builtin')
    F = scatteredInterpolant(C(:,1), C(:,2), f(:), 'linear', 'nearest');
    v = F(Q(:,1), Q(:,2));
else
    v = griddata(C(:,1), C(:,2), f(:), Q(:,1), Q(:,2), 'linear');
    nn = isnan(v); if any(nn), v(nn) = f(dsearchn(C, Q(nn,:))); end
end
end
