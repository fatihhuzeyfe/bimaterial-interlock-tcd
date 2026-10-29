%% ML_EXTRACT_DATASET  Builds the training set K(L/2 -> r) from the ML FEBio runs.
%  One FE run gives 2 constituents x numel(r_over_A) samples, because the stress
%  field is independent of the strength parameters (sigma0, KIc enter only via r).
clear; clc;
root = fileparts(fileparts(mfilename('fullpath'))); addpath(root);
cfg0 = study_config(); mldir = fullfile(root, cfg0.ml.outdir); S = load(fullfile(mldir, 'ml_cases.mat')); cases = S.cases; cfg = S.cfg; ml = cfg.ml; ml.outdir = mldir;
X = []; y = []; yg = []; grp = []; topoId = []; dom = []; nOK = 0;
for k = 1:numel(cases)
    cs = cases(k);
    if ~exist(fullfile(ml.outdir, cs.stressLog), 'file'), continue; end
    cache = fullfile(ml.outdir, ['feat_' cs.base '.mat']);
    if exist(cache, 'file')
        F = load(cache);
    else
        F = ml_extract_run(cs, ml, cfg);  save('-v7', cache, '-struct', 'F');
    end
    X = [X; F.X]; y = [y; F.y]; yg = [yg; F.yg]; grp = [grp; k*ones(size(F.y))]; %#ok<AGROW>
    topoId = [topoId; find(strcmp(cfg.topologies, cs.topo))*ones(size(F.y))]; dom = [dom; F.dom]; %#ok<AGROW>
    nOK = nOK + 1;
    fprintf('%-22s K_loc = %.3f..%.3f\n', cs.base, exp(max(F.y)), exp(min(F.y)));
end
names = {'A_over_lambda','theta_u_deg','alpha','beta','log_r_over_A'};
save('-v7', fullfile(ml.outdir, 'ml_dataset.mat'), 'X', 'y', 'yg', 'grp', 'topoId', 'dom', 'names', 'cfg');
fid = fopen(fullfile(ml.outdir, 'ml_dataset.csv'), 'w');
fprintf(fid, 'run,topology,domain,%s,log_K_local,log_K_global\n', strjoin(names, ','));
for i = 1:numel(y)
    fprintf(fid, '%d,%s,%d,%.6f,%.4f,%.6f,%.6f,%.6f,%.6f,%.6f\n', grp(i), cfg.topologies{topoId(i)}, dom(i), X(i,:), y(i), yg(i));
end
fclose(fid);
fprintf('\n%d runs -> %d samples written to %s/ml_dataset.mat/.csv\n', nOK, numel(y), ml.outdir);

