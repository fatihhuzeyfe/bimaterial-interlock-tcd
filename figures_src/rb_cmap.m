function c = rb_cmap(n)
%RB_CMAP  Diverging blue-white-red colormap (no toolbox required).
if nargin < 1, n = 256; end
t = linspace(-1, 1, n).';
c = [min(1, 1 + t), 1 - abs(t), min(1, 1 - t)];
c(t < 0, :) = [0.23 + 0.77*(1 + t(t<0)), 0.30 + 0.70*(1 + t(t<0)), 0.75 + 0.25*(1 + t(t<0))];
c(t >= 0, :) = [0.70 + 0.30*(1 - t(t>=0)), 0.02 + 0.98*(1 - t(t>=0)), 0.15 + 0.85*(1 - t(t>=0))];
end
