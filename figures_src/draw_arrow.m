function draw_arrow(p0, p1, col, lw, hs)
%DRAW_ARROW  Arrow from p0 to p1 in data coordinates (MATLAB & Octave).
%   hs = head size as a fraction of the arrow length (default 0.25).
if nargin < 3 || isempty(col), col = 'k'; end
if nargin < 4 || isempty(lw),  lw  = 1.2; end
if nargin < 5 || isempty(hs),  hs  = 0.25; end
d = p1 - p0; L = norm(d); if L == 0, return; end
u = d/L; n = [-u(2) u(1)]; h = hs*L; w = 0.45*h;
base = p1 - h*u;
plot([p0(1) base(1)], [p0(2) base(2)], '-', 'Color', col, 'LineWidth', lw);
patch([p1(1) base(1)+w*n(1) base(1)-w*n(1)], [p1(2) base(2)+w*n(2) base(2)-w*n(2)], col, 'EdgeColor', col);
end
