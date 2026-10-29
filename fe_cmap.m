function c = fe_cmap(n)
%FE_CMAP  Banded "turbo"-type colormap used for ALL contour figures (consistent FE style).
%   n = number of colour bands (default 14). Uses MATLAB's turbo if available.
if nargin < 1, n = 14; end
if exist('turbo', 'file') || exist('turbo', 'builtin')
    c = turbo(n);
else   % turbo approximation (no toolbox required)
    a = [0.190 0.072 0.232; 0.275 0.375 0.876; 0.161 0.663 0.976; 0.093 0.882 0.713; 0.459 0.996 0.341; ...
         0.808 0.920 0.200; 0.992 0.678 0.212; 0.937 0.373 0.075; 0.737 0.137 0.012; 0.480 0.016 0.011];
    c = interp1(linspace(0, 1, size(a,1)), a, linspace(0, 1, n));
end
end
