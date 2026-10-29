function robust_ylim(ax, pct)
%ROBUST_YLIM  y-limits from the 1st/99th percentiles of all line data (clips corner singularities).
if nargin < 2, pct = [1 99]; end
h = findobj(ax, 'Type', 'line'); y = [];
for k = 1:numel(h), yk = get(h(k), 'YData'); y = [y; yk(:)]; end %#ok<AGROW>
y = y(isfinite(y)); if isempty(y), return; end
y = sort(y); lo = y(max(1, round(pct(1)/100*numel(y)))); hi = y(min(numel(y), round(pct(2)/100*numel(y))));
pad = 0.1*max(hi - lo, eps); ylim(ax, [lo - pad, hi + pad]);
end
