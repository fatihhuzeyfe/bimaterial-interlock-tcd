function [x, n] = graded_nodes(a, b, cl, h0, hmax, g, N)
%GRADED_NODES  Node positions on [a,b] with spacing h0 at clustered ends
%   growing linearly (ratio ~g per element) up to hmax.
%   cl = [clusterA clusterB] (logical). If N is given, exactly N intervals.
xs = linspace(a, b, 4001);
d = inf(size(xs));
if cl(1), d = min(d, xs - a); end
if cl(2), d = min(d, b - xs); end
hloc = min(hmax, h0 + (g - 1)*d);
hloc(~isfinite(hloc)) = hmax;
cum = cumtrapz(xs, 1./hloc);
if nargin < 7 || isempty(N)
    N = max(1, round(cum(end)));
end
n = N;
x = interp1(cum/cum(end), xs, linspace(0, 1, N + 1));
x(1) = a; x(end) = b;
end
