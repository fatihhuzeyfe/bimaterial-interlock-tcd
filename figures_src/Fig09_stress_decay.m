%% FIG8_STRESS_DECAY  Log-log decay of the effective SCF K(r) = max sigma_1 on the r-locus / sigma_nom
%  in both constituents (pair TOP/BOT, scale S); TCD points r = L/2 marked; near-field slope fitted.
clear; close all;
here = fileparts(mfilename('fullpath')); addpath(here); root = fileparts(here); addpath(root);
TOP = 'PLA'; BOT = 'ABS'; S = 2;                      % <-- choose the pair and scale here
cfg = study_config(); topos = cfg.topologies; mk = {'o','s','^'};
fg = figure('Color','w','Position',[40 40 1300 430]); lt = 'abc';
fid = fopen(fullfile(fig_dir(), sprintf('Table_decay_exponents_%s_%s_s%s.csv', TOP, BOT, num2tag(S))), 'w');
fprintf(fid, 'topology,constituent,slope_near_field,K_at_Lhalf\n');
for d = [2 1]
    if d == 2, mt = cfg.mat(strcmp({cfg.mat.name}, TOP)); else, mt = cfg.mat(strcmp({cfg.mat.name}, BOT)); end
    ax = subplot(1, 3, 3 - d); hold on; box on; grid on; hl = [];
    for it = 1:3
        [M, Sg, sn] = load_case_fields(root, topos{it}, S, TOP, BOT);
        r = logspace(log10(3*M.h), log10(min(3*M.A, cfg.d_fine - 0.3)), 30);
        [~, Kg] = tcd_K_curve(M, Sg, sn, d, r, cfg);
        hl(end+1) = plot(r/M.A, Kg, ['-' mk{it}], 'LineWidth', 1.2, 'MarkerSize', 4); %#ok<SAGROW>
        nf = r < 0.3*M.A; pp = polyfit(log(r(nf)), log(max(Kg(nf) - 1, 1e-6)), 1);
        [~, KL] = tcd_K_curve(M, Sg, sn, d, mt.L/2, cfg);
        hs = plot((mt.L/2)/M.A, KL, 'kp', 'MarkerFaceColor', 'y', 'MarkerSize', 11);
        fprintf(fid, '%s,%s,%.4f,%.5f\n', topos{it}, mt.name, pp(1), KL);
    end
    set(ax, 'XScale', 'log', 'YScale', 'log');
    if d == 2, legend([hl hs], [topos, {'r = L/2'}], 'Location', 'southwest', 'FontSize', 8, 'Box', 'off'); end
    panel_label(ax, lt(3 - d), 'r/A', 'K(r)');
end
fclose(fid);
% (c) governing strength ratio of all production cases vs A/(L/2) (from results.mat, if available)
ax = subplot(1, 3, 3); hold on; box on; grid on;
rf = fullfile(root, 'results.mat');
if exist(rf, 'file') == 2
    R = load(rf); res = R.res(~[R.res.convOnly] & ~strcmp({R.res.top}, {R.res.bot}));
    for it = 1:3
        sel = strcmp({res.topo}, topos{it});
        x = arrayfun(@(q) q.dom(q.gov1_domain).A_over_r, res(sel)); Kg = arrayfun(@(q) q.dom(q.gov1_domain).K, res(sel));
        plot(x, Kg, mk{it}, 'MarkerSize', 6, 'LineWidth', 1);
    end
    set(ax, 'XScale', 'log');
    legend(topos, 'Location', 'northwest', 'FontSize', 8, 'Box', 'off');
end
panel_label(ax, 'c', 'A/(L/2)', 'K_{L/2}');
save_fig600(fg, 'Fig09_stress_decay');
