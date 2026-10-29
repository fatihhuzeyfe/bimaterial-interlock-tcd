function [Kloc, Kglob, sref] = tcd_K_curve(M, Sg, sig_nom, d, r_list, cfg)
%TCD_K_CURVE  Effective SCF on the L/2-type locus of constituent D for several distances r.
%   Kloc  = sigma_1,max(r) / far-field sigma_yy of the same constituent (assessed wavelength)
%   Kglob = sigma_1,max(r) / sigma_nom
cc = M.centroid;  yfar = (2*d - 3)*M.H/2;
ff = M.dom == d & cc(:,1) > M.xa & cc(:,1) < M.xb & abs(cc(:,2) - yfar) < 0.25*M.H;
sref = mean(Sg(ff, 2));
Pts = []; id = [];
for ir = 1:numel(r_list)
    p = tcd_locus(M.poly, r_list(ir), d, M.xa, M.xb, M.H, cfg);
    Pts = [Pts; p]; id = [id; ir*ones(size(p,1),1)]; %#ok<AGROW>
end
rw = max(r_list) + 1;
sel = M.dom == d & cc(:,1) > M.xa - rw & cc(:,1) < M.xb + rw & abs(cc(:,2)) < M.A + rw;
V = interp_centroids(cc(sel,:), Sg(sel,:), Pts);
s1 = (V(:,1) + V(:,2))/2 + sqrt(((V(:,1) - V(:,2))/2).^2 + V(:,3).^2);
Kloc = nan(numel(r_list),1); Kglob = Kloc;
for ir = 1:numel(r_list)
    smax = max(s1(id == ir & isfinite(s1)));
    Kloc(ir) = smax/sref; Kglob(ir) = smax/sig_nom;
end
end
