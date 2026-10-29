%% TIED_COMPARE  Shared-node vs tied-contact results (requires results.mat of the production runs).
clear; clc;
root = fileparts(mfilename('fullpath')); addpath(root);
cfg0 = study_config(); out = fullfile(root, cfg0.tied.outdir);
C = load(fullfile(out, 'cases.mat')); cases = C.cases; cfg = C.cfg;
P = load(fullfile(root, 'results.mat')); res = P.res;
fid = fopen(fullfile(fig_dir(), 'Table_tied_contact.csv'), 'w');
fprintf(fid, 'scale,pair,interface,penalty,peak_s1_over_snom,K_Lhalf_gov,eta,delta_eta_percent\n');
T = struct([]);
for k = 1:numel(cases)
    cs = cases(k);
    if ~exist(fullfile(out, cs.stressLog), 'file'), fprintf('missing: %s\n', cs.base); continue; end
    M = load(fullfile(out, ['mesh_' cs.tag '.mat'])); M = M.M;
    R = evaluate_case(cs, M, cfg, out);
    [Sg, sn] = read_case_stress(M, out, cs.stressLog, cs.reactLog, cfg.t);
    s1 = (Sg(:,1) + Sg(:,2))/2 + sqrt(((Sg(:,1) - Sg(:,2))/2).^2 + Sg(:,3).^2);
    band = M.centroid(:,1) > M.xa & M.centroid(:,1) < M.xb & abs(M.centroid(:,2)) < M.A + 0.3;
    pk = max(s1(band))/sn;
    j = find(strcmp({res.topo}, cs.topo) & abs([res.scale] - cs.scale) < 1e-9 & strcmp({res.top}, cs.top) & ...
             strcmp({res.bot}, cs.bot) & ~[res.convOnly], 1);
    if isempty(j), error('Shared-node reference missing in results.mat for %s', cs.base); end
    % shared-node reference (peak from the production logs)
    [Ms, Ss, sns] = load_ref_case(root, res(j), cfg);
    s1s = (Ss(:,1) + Ss(:,2))/2 + sqrt(((Ss(:,1) - Ss(:,2))/2).^2 + Ss(:,3).^2);
    bs = Ms.centroid(:,1) > Ms.xa & Ms.centroid(:,1) < Ms.xb & abs(Ms.centroid(:,2)) < Ms.A + 0.3;
    pks = max(s1s(bs))/sns;
    de = 100*(R.eta1 - res(j).eta1)/res(j).eta1;
    if ~any(arrayfun(@(t) strcmp(t.key, sprintf('%g_%s/%s', cs.scale, cs.top, cs.bot)), T))
        fprintf(fid, '%g,%s/%s,shared,-,%.4f,%.4f,%.4f,0\n', cs.scale, cs.top, cs.bot, pks, res(j).dom(res(j).gov1_domain).K, res(j).eta1);
    end
    fprintf(fid, '%g,%s/%s,tied,%.0e,%.4f,%.4f,%.4f,%.3f\n', cs.scale, cs.top, cs.bot, cs.penalty, pk, R.dom(R.gov1_domain).K, R.eta1, de);
    t = struct('key', sprintf('%g_%s/%s', cs.scale, cs.top, cs.bot), 'scale', cs.scale, 'pair', [cs.top '/' cs.bot], ...
               'penalty', cs.penalty, 'peak', pk, 'peak_shared', pks, 'eta', R.eta1, 'eta_shared', res(j).eta1, 'deta', de, 'base', cs.base);
    T = [T, t]; %#ok<AGROW>
    fprintf('%-45s peak %.3f (shared %.3f)  eta %.4f (shared %.4f)  d_eta %+.2f %%\n', cs.base, pk, pks, R.eta1, res(j).eta1, de);
end
fclose(fid);
save(fullfile(root, 'tied_results.mat'), 'T');
disp('tied_results.mat and figures/Table_tied_contact.csv written');

