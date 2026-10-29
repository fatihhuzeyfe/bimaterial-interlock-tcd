%% FIG04_VERIFICATION  (a-c) mono-material verification, (d) failure-load convergence,
%  (e) K_{L/2} and (f) eta with Richardson extrapolation and GCI. Writes Table_GCI.csv.
clear; close all;
here = fileparts(mfilename('fullpath')); addpath(here); root = fileparts(here); addpath(root);
S = load(fullfile(root, 'results.mat')); res = S.res; cfg = S.cfg;
topos = cfg.topologies; names = {cfg.mat.name}; mk = {'o','s','^'};
cl = [0.00 0.45 0.74; 0.85 0.33 0.10]; lt = 'abcdef';
prod = ~[res.convOnly];
tiedFile = fullfile(root, 'tied_results.mat'); haveTied = exist(tiedFile, 'file') == 2;
nr = 2 + haveTied;
fg = figure('Color','w','Position',[40 40 1250 380*nr]);
% (a)-(c) mono-material joints: sigma_1/sigma_nom along the critical path
for im = 1:3
    ax = subplot(nr,3,im); hold on; box on; grid on;
    for it = 1:3
        k = find(prod & strcmp({res.topo}, topos{it}) & [res.scale] == 1 & strcmp({res.top}, names{im}) & strcmp({res.bot}, names{im}), 1);
        if isempty(k), continue; end
        D = res(k).dom(2);
        plot(D.path.r, D.path.s1/res(k).sig_nom, ['-' mk{it}], 'LineWidth', 1.2, 'MarkerSize', 4, 'MarkerIndices', 1:8:numel(D.path.r));
    end
    ylim([0.98 1.02]);
    if im == 1, legend(topos, 'Location', 'southwest', 'Box', 'off'); end
    panel_label(ax, lt(im), 'r (mm)', '\sigma_1/\sigma_{nom}');
end
% convergence data
fid = fopen(fullfile(fig_dir(), 'Table_GCI.csv'), 'w');
fprintf(fid, 'topology,pair,quantity,f_h0.04,f_h0.02,f_h0.01,order_p,f_extrapolated,GCI_fine_percent,asymptotic_ratio\n');
ax4 = subplot(nr,3,4); hold on; box on; grid on;
ax5 = subplot(nr,3,5); hold on; box on; grid on;
ax6 = subplot(nr,3,6); hold on; box on; grid on;
hh = []; lg = {};
for it = 1:3
    for ip = 1:size(cfg.conv_pairs,1)
        sel = find(strcmp({res.topo}, topos{it}) & abs([res.scale] - cfg.conv_scale) < 1e-9 & ...
              strcmp({res.top}, cfg.conv_pairs{ip,1}) & strcmp({res.bot}, cfg.conv_pairs{ip,2}));
        if numel(sel) < 3, continue; end
        [h, o] = sort([res(sel).h]); rr = res(sel(o));
        P = [rr.Pfail1]; K = arrayfun(@(r) r.dom(r.gov1_domain).K, rr); E = [rr.eta1];
        hh(end+1) = plot(ax4, h, 100*(P - P(1))/P(1), ['-' mk{it}], 'Color', cl(ip,:), 'MarkerFaceColor', cl(ip,:), 'LineWidth', 1.2); %#ok<SAGROW>
        lg{end+1} = sprintf('%s %s/%s', topos{it}(1:3), cfg.conv_pairs{ip,:}); %#ok<SAGROW>
        qs = {K, E}; qn = {'K(L/2)', 'eta'}; axs = [ax5 ax6];
        for q = 1:2
            f = qs{q}; G = gci3(h, f);
            plot(axs(q), h, f, ['-' mk{it}], 'Color', cl(ip,:), 'MarkerFaceColor', cl(ip,:), 'LineWidth', 1.2);
            plot(axs(q), 0, G.f_ext, mk{it}, 'Color', cl(ip,:), 'MarkerSize', 8);
            errorbar(axs(q), h(1), f(1), G.GCI_fine*abs(f(1)), 'Color', cl(ip,:));
            fprintf(fid, '%s,%s/%s,%s,%.6f,%.6f,%.6f,%.3f,%.6f,%.4f,%.4f\n', topos{it}, cfg.conv_pairs{ip,:}, qn{q}, ...
                f(3), f(2), f(1), G.p, G.f_ext, 100*G.GCI_fine, G.asymptotic);
        end
    end
end
fclose(fid);
set(ax4, 'XScale', 'log', 'XTick', [0.01 0.02 0.04]); legend(ax4, hh, lg, 'Location', 'best', 'FontSize', 7, 'Box', 'off');
panel_label(ax4, 'd', 'h (mm)', '\DeltaP_{fail} (%)');
xlim(ax5, [-0.003 0.045]); panel_label(ax5, 'e', 'h (mm)', 'K_{L/2}');
xlim(ax6, [-0.003 0.045]); panel_label(ax6, 'f', 'h (mm)', '\eta');
if haveTied
    % (g)-(h) mono-material ABS/ABS dovetail at s = 2: shared nodes vs tied contact (penalty 1e4)
    TR = load(tiedFile); T = TR.T; c0 = study_config(); tc = c0.tied;
    C = load(fullfile(root, tc.outdir, 'cases.mat'));
    k = find(strcmp({C.cases.top}, 'ABS') & strcmp({C.cases.bot}, 'ABS') & [C.cases.scale] == max(tc.scales) & ...
             [C.cases.penalty] == min(tc.penalties), 1);
    cs = C.cases(k); Mt = load(fullfile(root, tc.outdir, ['mesh_' cs.tag '.mat'])); Mt = Mt.M;
    [St, snt] = read_case_stress(Mt, fullfile(root, tc.outdir), cs.stressLog, cs.reactLog, cfg.t);
    [Ms, Ss, sns] = load_case_fields(root, tc.topo, max(tc.scales), 'ABS', 'ABS');
    F = {Ms, Ss, sns; Mt, St, snt};
    for q = 1:2
        M = F{q,1}; Sg = F{q,2}; sn = F{q,3};
        s1 = (Sg(:,1) + Sg(:,2))/2 + sqrt(((Sg(:,1) - Sg(:,2))/2).^2 + Sg(:,3).^2);
        c = M.centroid; w = [M.xa - 0.25*M.lambda, M.xb + 0.25*M.lambda]; yl = [-M.A - 1.2, M.A + 1.2]; pad = 0.3;
        sel = sel_window(M.quads, M.nodes, w, yl);
        ax = subplot(nr, 3, 6 + q); hold on; box on; axis equal;
        field_contour(ax, c, M.dom, s1/sn, M.poly, w, yl, linspace(0.8, 1.25, 19));
        plot(M.poly(:,1), M.poly(:,2), 'k-', 'LineWidth', 1); colormap(ax, fe_cmap(18)); axis([w yl]);
        if q == 2, cb = add_colorbar(ax, ''); title(cb, '\bf\sigma_1/\sigma_{nom}', 'FontSize', 9); end
        panel_label(ax, char('f' + q), 'x (mm)', 'y (mm)');
    end
    % (i) change of the predicted strength ratio with respect to the shared-node solution
    ax = subplot(nr, 3, 9); hold on; box on; grid on;
    lab = arrayfun(@(t) sprintf('%s, s=%g', t.pair, t.scale), T, 'UniformOutput', false);
    ul = unique(lab, 'stable'); up = unique([T.penalty]); Y = nan(numel(ul), numel(up));
    for a = 1:numel(T), Y(strcmp(ul, lab{a}), up == T(a).penalty) = T(a).deta; end
    hb = bar(Y); set(ax, 'XTick', 1:numel(ul), 'XTickLabel', ul, 'XTickLabelRotation', 20);
    legend(hb, arrayfun(@(p) sprintf('p = %.0e', p), up, 'UniformOutput', false), 'Location', 'best', 'FontSize', 8, 'Box', 'off');
    panel_label(ax, 'i', '', '\Delta\eta (%)');
    p = get(ax, 'Position'); set(ax, 'Position', [p(1) + 0.035, p(2), p(3) - 0.035, p(4)]);   % room for the colorbar of (h)
end
save_fig600(fg, 'Fig04_verification'); save_fig_vector(fg, 'Fig04_verification');
