function [M, Sg, sn, cs, cfg] = load_case_fields(root, topo, s, top, bot)
%LOAD_CASE_FIELDS  Mesh, element stresses (t = 1) and nominal stress of one production case.
cfg0 = study_config(); C = load(fullfile(root, cfg0.outdir, 'cases.mat')); cfg = C.cfg;
k = find(strcmp({C.cases.topo}, topo) & abs([C.cases.scale] - s) < 1e-9 & strcmp({C.cases.top}, top) & ...
         strcmp({C.cases.bot}, bot) & ~[C.cases.convOnly], 1);
if isempty(k), error('Case %s s=%g %s/%s not found', topo, s, top, bot); end
cs = C.cases(k); folder = fullfile(root, cfg.outdir);
T = load(fullfile(folder, ['mesh_' cs.tag '.mat'])); M = T.M;
[Sg, sn] = read_case_stress(M, folder, cs.stressLog, cs.reactLog, cfg.t);
end
