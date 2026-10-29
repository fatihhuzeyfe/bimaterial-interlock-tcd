function c = seq_cmap(n)
%SEQ_CMAP  Perceptually uniform sequential colormap (viridis-like), no toolbox required.
if nargin < 1, n = 256; end
a = [0.267 0.005 0.329; 0.283 0.141 0.458; 0.254 0.265 0.530; 0.207 0.372 0.553; 0.164 0.471 0.558; ...
     0.128 0.567 0.551; 0.135 0.659 0.518; 0.267 0.749 0.441; 0.478 0.821 0.318; 0.741 0.873 0.150; 0.993 0.906 0.144];
c = interp1(linspace(0, 1, size(a,1)), a, linspace(0, 1, n));
end
