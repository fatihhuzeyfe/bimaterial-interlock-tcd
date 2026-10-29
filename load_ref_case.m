function [M, S, sn] = load_ref_case(root, r, cfg)
%LOAD_REF_CASE  Mesh and stresses of the shared-node production case corresponding to result r.
C = load(fullfile(root, cfg.outdir, 'cases.mat'));
k = find(strcmp({C.cases.base}, r.base), 1); cs = C.cases(k);
M = load(fullfile(root, cfg.outdir, ['mesh_' cs.tag '.mat'])); M = M.M;
[S, sn] = read_case_stress(M, fullfile(root, cfg.outdir), cs.stressLog, cs.reactLog, cfg.t);
end
