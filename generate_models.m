%% GENERATE_MODELS  Builds all meshes and FEBio input files of the study.
%  Production : 3 topologies x 4 scales x 9 material pairs (h = cfg.h_prod)
%  Convergence: 3 topologies x cfg.h_conv (scale = cfg.conv_scale) x cfg.conv_pairs
%  Output     : <outdir>/*.feb, mesh_*.mat, cases.mat, run_all_febio.bat/.sh
clear; clc;
cfg = study_config();
if ~exist(cfg.outdir, 'dir'), mkdir(cfg.outdir); end
names = {cfg.mat.name};

% ---- geometry list: {topology, scale, h, isConvergenceOnly}
G = {};
for it = 1:numel(cfg.topologies)
    for s = cfg.scales, G(end+1,:) = {cfg.topologies{it}, s, cfg.h_prod, false}; end %#ok<SAGROW>
    for h = cfg.h_conv
        if abs(h - cfg.h_prod) > 1e-12
            G(end+1,:) = {cfg.topologies{it}, cfg.conv_scale, h, true}; %#ok<SAGROW>
        end
    end
end

cases = struct([]);
for ig = 1:size(G,1)
    [topo, s, h, convOnly] = G{ig,:};
    A = cfg.A0*s;  lam = cfg.lambda0*s;
    tag = sprintf('%s_s%s_h%s', topo, num2tag(s), num2tag(h));
    M = build_mesh(topo, A, lam, h, cfg);
    U = cfg.eps_ref*2*M.H;
    save('-v7', fullfile(cfg.outdir, ['mesh_' tag '.mat']), 'M');
    fprintf('[%2d/%2d] %-28s elems=%7d  aspect_max=%5.1f  jac_min=%4.2f\n', ...
        ig, size(G,1), tag, M.nElem, M.quality.max_aspect, M.quality.min_jac_ratio);

    for iT = 1:3
        for iB = 1:3
            if convOnly && ~any(strcmp(cfg.conv_pairs(:,1), names{iT}) & strcmp(cfg.conv_pairs(:,2), names{iB}))
                continue;
            end
            base = sprintf('AM_%s_T%s_B%s', tag, names{iT}, names{iB});
            k = numel(cases) + 1;
            cases(k).base = base;          cases(k).tag = tag;       %#ok<SAGROW>
            cases(k).topo = topo;          cases(k).scale = s;       cases(k).h = h;
            cases(k).A = A;                cases(k).lambda = lam;
            cases(k).top = names{iT};      cases(k).bot = names{iB};
            cases(k).iTop = iT;            cases(k).iBot = iB;
            cases(k).U = U;                cases(k).convOnly = convOnly;
            cases(k).feb = [base '.feb'];
            cases(k).stressLog = ['S_' base '.txt'];
            cases(k).reactLog  = ['R_' base '.txt'];
            write_feb(fullfile(cfg.outdir, cases(k).feb), M, cfg.mat(iT), cfg.mat(iB), U, cfg, ...
                      cases(k).stressLog, cases(k).reactLog);
        end
    end
end
save('-v7', fullfile(cfg.outdir, 'cases.mat'), 'cases', 'cfg');

% ---- batch runners (Windows .bat is a static file shipped with the package)
here = fileparts(mfilename('fullpath'));
copyfile(fullfile(here, 'run_all_febio.bat'), fullfile(cfg.outdir, 'run_all_febio.bat'));
fs = fopen(fullfile(cfg.outdir, 'run_all_febio.sh'), 'w');
fprintf(fs, '#!/bin/bash\nFEBIO=${FEBIO:-febio3}\ncd "$(dirname "$0")"\n');
fprintf(fs, 'for f in AM_*.feb; do b=${f%%.feb}; grep -q "N O R M A L" "$b.log" 2>/dev/null && continue; echo "$b"; $FEBIO -i "$f" >> febio_run_log.txt 2>&1; done\n');
fclose(fs);
fprintf('\n%d FEBio models written to ./%s\n', numel(cases), cfg.outdir);

