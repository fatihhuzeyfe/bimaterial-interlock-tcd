function R = evaluate_case(cs, M, cfg, folder)
%EVALUATE_CASE  Post-processes one FEBio run with the TCD Point Method.
%  Primary criterion   : max. principal stress at the L/2 locus  (Susmel & Taylor 2008)
%  Secondary criterion : quadratic interaction of interface-normal/-tangential
%                        stresses at the L/2 locus  (sigma_n/sigma0)^2 + (tau_t/tau0)^2
%  Both constituents are assessed (competing criterion); the lower load governs.
Rb = read_febio_log(fullfile(folder, cs.reactLog));
Sb = read_febio_log(fullfile(folder, cs.stressLog));
[~, i1] = max([Rb.time]);  [~, i05] = min(abs([Rb.time] - 0.5));
[~, j1] = max([Sb.time]);  [~, j05] = min(abs([Sb.time] - 0.5));
P1  = abs(sum(Rb(i1).data(:,2)))  / cfg.t;     % reaction per unit thickness [N/mm] (FEBio sign: negative)
P05 = abs(sum(Rb(i05).data(:,2))) / cfg.t;

% element stresses at t = 1 mapped to quads
S = nan(M.nElem, 3);  S05 = S;
S(M.elemOrder(Sb(j1).data(:,1)), :)    = Sb(j1).data(:,2:4);
S05(M.elemOrder(Sb(j05).data(:,1)), :) = Sb(j05).data(:,2:4);
big = abs(S(:,2)) > 1e-3*max(abs(S(:,2)));
R.lin_P = P05/P1;                                % should be 0.5
R.lin_S = median(S05(big,2)./S(big,2));          % should be 0.5

R.base = cs.base; R.topo = cs.topo; R.scale = cs.scale; R.h = cs.h; R.A = cs.A;
R.top = cs.top; R.bot = cs.bot; R.convOnly = cs.convOnly;
R.P_ref = P1;  R.U_ref = cs.U;  R.sig_nom = P1/M.W;  R.K_global = P1/cs.U;

mats = [cs.iBot, cs.iTop];      % domain 1 = bottom, 2 = top
for d = 1:2
    mt = cfg.mat(mats(d));  r = mt.L/2;
    [pts, q, nv] = tcd_locus(M.poly, r, d, M.xa, M.xb, M.H, cfg);
    sel = M.dom == d & M.centroid(:,1) > M.xa - r - 1 & M.centroid(:,1) < M.xb + r + 1 ...
          & abs(M.centroid(:,2)) < M.A + r + 1;
    V = interp_centroids(M.centroid(sel,:), S(sel,:), pts);
    good = all(isfinite(V), 2);  pts = pts(good,:); q = q(good,:); nv = nv(good,:); V = V(good,:);
    sx = V(:,1); sy = V(:,2); txy = V(:,3);
    s1 = (sx + sy)/2 + sqrt(((sx - sy)/2).^2 + txy.^2);
    sn = sx.*nv(:,1).^2 + sy.*nv(:,2).^2 + 2*txy.*nv(:,1).*nv(:,2);
    tt = (sy - sx).*nv(:,1).*nv(:,2) + txy.*(nv(:,1).^2 - nv(:,2).^2);   % = t' * sigma * n
    I1 = (max(s1, 0)/mt.sigma0).^2;
    Iq = (max(sn, 0)/mt.sigma0).^2 + (tt/mt.tau0).^2;
    [I1m, k1] = max(I1);  [Iqm, kq] = max(Iq);
    D.mat = mt.name; D.L = mt.L; D.r = r;
    D.I1 = I1m; D.Iq = Iqm;
    D.s1 = s1(k1); D.sn = sn(kq); D.tt = tt(kq);
    D.K = s1(k1)/R.sig_nom;                          % effective SCF at L/2
    D.A_over_r = M.A/r;
    D.p1 = pts(k1,:); D.q1 = q(k1,:); D.n1 = nv(k1,:);
    D.mode_mix = atan2d(abs(tt(kq)), max(sn(kq), eps)); % loading angle at the critical point
    D.Pfail1 = P1/sqrt(I1m);  D.Pfailq = P1/sqrt(Iqm);
    D.locus = struct('pts', pts, 'sn', sn/mt.sigma0, 'tt', tt/mt.tau0, 's1', s1/mt.sigma0);
    % stress path from the critical interface point along its normal
    sp = linspace(0, cfg.path_len, 81).';
    pp = D.q1 + sp*D.n1;
    Vp = interp_centroids(M.centroid(M.dom == d,:), S(M.dom == d,:), pp);
    s1p = (Vp(:,1) + Vp(:,2))/2 + sqrt(((Vp(:,1) - Vp(:,2))/2).^2 + Vp(:,3).^2);
    snp = Vp(:,1)*D.n1(1)^2 + Vp(:,2)*D.n1(2)^2 + 2*Vp(:,3)*D.n1(1)*D.n1(2);
    ttp = (Vp(:,2) - Vp(:,1))*D.n1(1)*D.n1(2) + Vp(:,3)*(D.n1(1)^2 - D.n1(2)^2);
    D.path = struct('r', sp, 's1', s1p, 'sn', snp, 'tt', ttp);
    R.dom(d) = D;
end
% competing criterion: the constituent that fails first governs
[R.I1_gov, g1] = max([R.dom.I1]);   [R.Iq_gov, gq] = max([R.dom.Iq]);
R.gov1 = R.dom(g1).mat;  R.govq = R.dom(gq).mat;  R.gov1_domain = g1;
R.Pfail1 = P1/sqrt(R.I1_gov);  R.Ufail1 = cs.U/sqrt(R.I1_gov);
R.Pfailq = P1/sqrt(R.Iq_gov);  R.Ufailq = cs.U/sqrt(R.Iq_gov);
R.eta1 = (R.Pfail1/M.W)/cfg.mat(mats(g1)).sigma0;   % nominal strength / inherent strength
end
