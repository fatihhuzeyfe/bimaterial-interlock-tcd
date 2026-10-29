function d = graded_depth(D, h, cfg)
%GRADED_DEPTH  Distances 0..D from the interface: h at the interface, growing
%   to hmid = cfg.hmid_factor*h, uniform up to cfg.d_fine, then coarsening
%   (ratio 1.25) up to D/8 towards the loaded/fixed boundary.
g  = cfg.growth;  hmid = cfg.hmid_factor*h;  hfar = max(hmid, min(D/8, 0.5));
xs = linspace(0, D, 8001);
hl = min(hmid, h + (g - 1)*xs);
far = xs > cfg.d_fine;
hl(far) = min(hfar, hmid + (1.25 - 1)*(xs(far) - cfg.d_fine));
cum = cumtrapz(xs, 1./hl);
N = max(2, round(cum(end)));
d = interp1(cum/cum(end), xs, linspace(0, 1, N + 1));
d(1) = 0; d(end) = D;
end
