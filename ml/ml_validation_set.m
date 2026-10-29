function V = ml_validation_set(root)
%ML_VALIDATION_SET  Independent test set: the production FEBio analyses with the real
%   PLA/ABS/PC properties, evaluated at r = L/2 of each constituent (bi-material cases only).
cfg0 = study_config(); S = load(fullfile(root, cfg0.outdir, 'cases.mat')); cases = S.cases; cfg = S.cfg;
folder = fullfile(root, cfg.outdir);
V.X = []; V.y = []; V.topoId = []; V.label = {}; V.pair = {}; V.dom = [];
for k = 1:numel(cases)
    cs = cases(k);
    if cs.convOnly || strcmp(cs.top, cs.bot) || ~exist(fullfile(folder, cs.stressLog), 'file'), continue; end
    T = load(fullfile(folder, ['mesh_' cs.tag '.mat'])); M = T.M;
    [Sg, sn] = read_case_stress(M, folder, cs.stressLog, cs.reactLog, cfg.t);
    th = 0; if strcmp(cs.topo, 'Dovetail'), th = cfg.dovetail_undercut_deg; end
    idx = [cs.iBot, cs.iTop];
    for d = 1:2
        m1 = cfg.mat(idx(d)); m2 = cfg.mat(idx(3 - d));
        [al, be] = dundurs(m1.E, m1.nu, m2.E, m2.nu);
        Kl = tcd_K_curve(M, Sg, sn, d, m1.L/2, cfg);
        V.X = [V.X; cs.A/cs.lambda, th, al, be, log((m1.L/2)/cs.A)];
        V.y = [V.y; log(Kl)]; V.topoId = [V.topoId; find(strcmp(cfg.topologies, cs.topo))];
        V.label{end+1,1} = sprintf('%s s=%g %s/%s in %s', cs.topo, cs.scale, cs.top, cs.bot, m1.name);
        V.pair{end+1,1} = sprintf('%s-%s', m1.name, m2.name); V.dom = [V.dom; d];
    end
end
end
