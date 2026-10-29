function cb = add_colorbar(ax, label, equalAspect)
%ADD_COLORBAR  Colorbar that does NOT shrink the axes (all panels keep the same size).
%   The bar is placed just right of the visible plot box (accounts for 'axis equal').
if nargin < 3, equalAspect = true; end
set(ax, 'Units', 'normalized'); p = get(ax, 'Position');
cb = colorbar(ax); set(ax, 'Position', p);                 % undo the automatic shrinking
fu = get(ancestor(ax, 'figure'), 'Position');             % figure size in pixels
box = p;                                                   % visible plot box (normalized)
if equalAspect
    lim = axis(ax); ar = (lim(2) - lim(1))/(lim(4) - lim(3));
    wpx = p(3)*fu(3); hpx = p(4)*fu(4);
    if wpx/hpx > ar, w = hpx*ar/fu(3); box = [p(1) + (p(3) - w)/2, p(2), w, p(4)];
    else,            h = wpx/ar/fu(4); box = [p(1), p(2) + (p(4) - h)/2, p(3), h]; end
end
set(cb, 'Position', [box(1) + box(3) + 0.006, box(2), 0.010, box(4)], 'FontSize', 9);
if nargin > 1 && ~isempty(label), ylabel(cb, ['\bf' label], 'FontSize', 10); end
end
