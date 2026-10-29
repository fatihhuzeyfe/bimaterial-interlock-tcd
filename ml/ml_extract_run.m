function F = ml_extract_run(cs, ml, cfg)
%ML_EXTRACT_RUN  Features and targets of one ML FE run (both constituents, all r/A).
T = load(fullfile(ml.outdir, ['mesh_' cs.base '.mat'])); M = T.M;
[Sg, sn] = read_case_stress(M, ml.outdir, cs.stressLog, cs.reactLog, cfg.t);
F.X = []; F.y = []; F.yg = []; F.dom = [];
for d = 1:2
    if d == 2, E1 = cs.Eratio*ml.E_ref; n1 = cs.nuT; E2 = ml.E_ref; n2 = cs.nuB;
    else,      E1 = ml.E_ref; n1 = cs.nuB; E2 = cs.Eratio*ml.E_ref; n2 = cs.nuT; end
    [al, be] = dundurs(E1, n1, E2, n2);
    [Kl, Kg] = tcd_K_curve(M, Sg, sn, d, ml.A*ml.r_over_A, cfg);
    n = numel(ml.r_over_A);
    F.X = [F.X; repmat([cs.Alam, cs.theta, al, be], n, 1), log(ml.r_over_A(:))];
    F.y = [F.y; log(Kl)]; F.yg = [F.yg; log(Kg)]; F.dom = [F.dom; d*ones(n,1)];
end
end
