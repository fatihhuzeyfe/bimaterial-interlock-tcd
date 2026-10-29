%% GEN_TIED_COMPARISON  FEBio models identical to the production models except that the two
%  constituents are connected by a penalty tied contact (duplicated interface nodes).
%  Solve them with run_febio_all('tied_models'), then run tied_compare.
clear; clc;
root = fileparts(mfilename('fullpath')); addpath(root);
cfg = study_config(); tc = cfg.tied; out = fullfile(root, tc.outdir);
if exist(out, 'dir') ~= 7, mkdir(out); end
names = {cfg.mat.name}; cases = struct([]);
for s = tc.scales
    M = build_mesh(tc.topo, cfg.A0*s, cfg.lambda0*s, cfg.h_prod, cfg);
    T = make_tied_mesh(M); tag = sprintf('%s_s%s_h%s_tied', tc.topo, num2tag(s), num2tag(cfg.h_prod));
    M = T; save('-v7', fullfile(out, ['mesh_' tag '.mat']), 'M');
    fprintf('%s: %d interface facets, %d duplicated nodes\n', tag, size(T.iface_bot,1), T.nIfaceNodes);
    for ip = 1:size(tc.pairs,1)
        iT = find(strcmp(names, tc.pairs{ip,1})); iB = find(strcmp(names, tc.pairs{ip,2}));
        for pen = tc.penalties
            c = cfg; c.tied_penalty = pen;
            base = sprintf('TIED_%s_T%s_B%s_p%s', tag, names{iT}, names{iB}, strrep(sprintf('%.0e', pen), '+0', ''));
            k = numel(cases) + 1;
            cases(k).base = base; cases(k).tag = tag; cases(k).topo = tc.topo; cases(k).scale = s; %#ok<SAGROW>
            cases(k).h = cfg.h_prod; cases(k).A = cfg.A0*s; cases(k).lambda = cfg.lambda0*s;
            cases(k).top = names{iT}; cases(k).bot = names{iB}; cases(k).iTop = iT; cases(k).iBot = iB;
            cases(k).U = cfg.eps_ref*2*T.H; cases(k).convOnly = false; cases(k).penalty = pen;
            cases(k).feb = [base '.feb']; cases(k).stressLog = ['S_' base '.txt']; cases(k).reactLog = ['R_' base '.txt'];
            write_feb(fullfile(out, cases(k).feb), T, cfg.mat(iT), cfg.mat(iB), cases(k).U, c, cases(k).stressLog, cases(k).reactLog);
        end
    end
end
save('-v7', fullfile(out, 'cases.mat'), 'cases', 'cfg');
fprintf('%d tied-contact models written to %s\n', numel(cases), out);
