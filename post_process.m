%% POST_PROCESS  Reads all FEBio logs, applies the TCD and writes the results.
%  Run from the folder that contains study_config.m after FEBio has finished.
clear; clc;
cfg0 = study_config();
S = load(fullfile(cfg0.outdir, 'cases.mat'));  cases = S.cases;  cfg = S.cfg;
res = {};  meshCache = struct('tag', {}, 'M', {});
for k = 1:numel(cases)
    cs = cases(k);
    if ~exist(fullfile(cfg.outdir, cs.stressLog), 'file') || ~exist(fullfile(cfg.outdir, cs.reactLog), 'file')
        fprintf('  missing logs -> skipped: %s\n', cs.base); continue;
    end
    im = find(strcmp({meshCache.tag}, cs.tag));
    if isempty(im)
        T = load(fullfile(cfg.outdir, ['mesh_' cs.tag '.mat']));
        meshCache(end+1) = struct('tag', cs.tag, 'M', T.M); im = numel(meshCache); %#ok<SAGROW>
    end
    R = evaluate_case(cs, meshCache(im).M, cfg, cfg.outdir);
    res{end+1} = R; %#ok<SAGROW>
    fprintf('%-40s Pfail=%7.3f N/mm  gov=%-3s  K(L/2)=%.3f  lin=%.4f\n', cs.base, R.Pfail1, R.gov1, ...
        R.dom(R.gov1_domain).K, R.lin_P);
end
res = [res{:}];
save('-v7', 'results.mat', 'res', 'cfg');

% ---------- results table (CSV) ----------
fid = fopen('results_table.csv', 'w');
fprintf(fid, ['case,topology,scale,A_mm,h_mm,top,bottom,P_ref_Nmm,U_ref_mm,sigma_nom_MPa,', ...
    'K_top,K_bot,A_over_Lhalf_top,A_over_Lhalf_bot,I1_top,I1_bot,Iq_top,Iq_bot,', ...
    'governing_s1,Pfail_s1_Nmm,Ufail_s1_mm,eta_s1,governing_quad,Pfail_quad_Nmm,Ufail_quad_mm,', ...
    'modemix_top_deg,modemix_bot_deg,lin_P,lin_S,convergence_only\n']);
for k = 1:numel(res)
    R = res(k);
    fprintf(fid, '%s,%s,%g,%g,%g,%s,%s,%.5f,%.6f,%.4f,%.4f,%.4f,%.4f,%.4f,%.5f,%.5f,%.5f,%.5f,%s,%.5f,%.6f,%.4f,%s,%.5f,%.6f,%.2f,%.2f,%.5f,%.5f,%d\n', ...
        R.base, R.topo, R.scale, R.A, R.h, R.top, R.bot, R.P_ref, R.U_ref, R.sig_nom, ...
        R.dom(2).K, R.dom(1).K, R.dom(2).A_over_r, R.dom(1).A_over_r, R.dom(2).I1, R.dom(1).I1, ...
        R.dom(2).Iq, R.dom(1).Iq, R.gov1, R.Pfail1, R.Ufail1, R.eta1, R.govq, R.Pfailq, R.Ufailq, ...
        R.dom(2).mode_mix, R.dom(1).mode_mix, R.lin_P, R.lin_S, R.convOnly);
end
fclose(fid);

% ---------- verification & convergence summary ----------
fprintf('\n=== Verification ===\n');
fprintf('Linearity  P(0.5U)/P(U): min %.5f  max %.5f  (ideal 0.5)\n', min([res.lin_P]), max([res.lin_P]));
mono = strcmp({res.top}, {res.bot});
Km = arrayfun(@(r) max(abs([r.dom.K] - 1)), res(mono));
fprintf('Mono-material |K-1| at L/2: max %.2e  (ideal 0: homogeneous body)\n', max(Km));
fprintf('\n=== Mesh convergence (scale %g) ===\n', cfg.conv_scale);
fprintf('%-10s %-8s %8s %10s %10s\n', 'topology', 'pair', 'h [mm]', 'Pfail', 'dev [%]');
for it = 1:numel(cfg.topologies)
    for ip = 1:size(cfg.conv_pairs,1)
        sel = strcmp({res.topo}, cfg.topologies{it}) & [res.scale] == cfg.conv_scale & ...
              strcmp({res.top}, cfg.conv_pairs{ip,1}) & strcmp({res.bot}, cfg.conv_pairs{ip,2});
        rr = res(sel); if isempty(rr), continue; end
        [~, o] = sort([rr.h]); rr = rr(o); Pf = rr(1).Pfail1;   % finest mesh as reference
        for j = 1:numel(rr)
            fprintf('%-10s %-8s %8.3f %10.4f %10.3f\n', rr(j).topo, [rr(j).top '/' rr(j).bot], ...
                rr(j).h, rr(j).Pfail1, 100*(rr(j).Pfail1 - Pf)/Pf);
        end
    end
end
