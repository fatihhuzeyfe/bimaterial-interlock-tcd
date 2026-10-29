%% FIG4_TCD_LOCUS  Definition of the L/2 evaluation locus in both constituents (PLA top / ABS substrate).
%  If results.mat exists, the critical points of the corresponding FEBio analyses are marked.
clear; close all;
here = fileparts(mfilename('fullpath')); addpath(here); addpath(fileparts(here));   % figures_src and package root
cfg = study_config();
cTop = [0.957 0.635 0.380]; cBot = [0.557 0.792 0.902];
iT = find(strcmp({cfg.mat.name}, 'PLA')); iB = find(strcmp({cfg.mat.name}, 'ABS'));
rf = fullfile(fileparts(here), 'results.mat'); haveR = exist(rf, 'file') == 2; if haveR, S = load(rf); end
s = 2;                                              % A = 0.6 mm makes the geometry visible
fg = figure('Color','w','Position',[40 40 1500 500]);
for it = 1:3
    subplot(1,3,it); hold on; axis equal; box on;
    M = build_mesh(cfg.topologies{it}, cfg.A0*s, cfg.lambda0*s, 0.04, cfg);
    P = M.poly; ym = 2.2;
    patch([P(:,1); M.W; 0], [P(:,2); ym; ym], cTop, 'EdgeColor','none');
    patch([P(:,1); M.W; 0], [P(:,2); -ym; -ym], cBot, 'EdgeColor','none');
    plot(P(:,1), P(:,2), 'k-', 'LineWidth', 1.5);
    for d = 1:2
        if d == 2, mt = cfg.mat(iT); col = [0.45 0.10 0.50]; else, mt = cfg.mat(iB); col = [0.00 0.30 0.60]; end
        [pts, q] = tcd_locus(P, mt.L/2, d, M.xa, M.xb, M.H, cfg);
        [~, o] = sort(pts(:,1)); hL(d) = plot(pts(o,1), pts(o,2), '.', 'Color', col, 'MarkerSize', 4); %#ok<SAGROW>
    end
    if haveR
        k = find(strcmp({S.res.topo}, cfg.topologies{it}) & abs([S.res.scale] - s) < 1e-9 & ...
                 strcmp({S.res.top}, 'PLA') & strcmp({S.res.bot}, 'ABS') & ~[S.res.convOnly], 1);
        if ~isempty(k)
            D = S.res(k).dom(S.res(k).gov1_domain);
            plot([D.q1(1) D.p1(1)], [D.q1(2) D.p1(2)], 'r-', 'LineWidth', 1.5);
            hC = plot(D.p1(1), D.p1(2), 'rp', 'MarkerFaceColor','r', 'MarkerSize', 12);
        end
    end
    plot([M.xa M.xa], [-ym ym], 'k:'); plot([M.xb M.xb], [-ym ym], 'k:');
    axis([M.xa - 0.6, M.xb + 0.6, -ym, ym]);
    panel_label(gca, char('a' + it - 1), 'x (mm)', 'y (mm)');
    if it == 3
        hh = [hL(2) hL(1)]; lg = {'PLA', 'ABS'}; if haveR && exist('hC', 'var'), hh(end+1) = hC; lg{end+1} = 'Critical'; end
        legend(hh, lg, 'Location', 'northeast', 'FontSize', 8, 'Box', 'off');
    end
end
save_fig600(fg, 'Fig05_TCD_locus');
