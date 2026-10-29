%% FIG10_FAILURE_INDEX  TCD failure-index maps: sigma_1/sigma_0 of the local constituent at the
%  predicted failure load P_fail, with the L/2 loci, the isoline sigma_1/sigma_0 = 1 and the critical point.
clear; close all;
here = fileparts(mfilename('fullpath')); addpath(here); root = fileparts(here); addpath(root);
TOP = 'PLA'; BOT = 'ABS'; S = 2;                      % <-- pair and scale
cfg = study_config(); topos = cfg.topologies; lt = 'abc';
R = load(fullfile(root, 'results.mat')); res = R.res;
mt = cfg.mat(strcmp({cfg.mat.name}, TOP)); mb = cfg.mat(strcmp({cfg.mat.name}, BOT));
fg = figure('Color','w','Position',[40 40 1300 420]);
for it = 1:3
    [M, Sg, sn] = load_case_fields(root, topos{it}, S, TOP, BOT);
    k = find(strcmp({res.topo}, topos{it}) & abs([res.scale] - S) < 1e-9 & strcmp({res.top}, TOP) & ...
             strcmp({res.bot}, BOT) & ~[res.convOnly], 1);
    f = 1/sqrt(res(k).I1_gov);                             % scaling to the predicted failure load
    s1 = (Sg(:,1) + Sg(:,2))/2 + sqrt(((Sg(:,1) - Sg(:,2))/2).^2 + Sg(:,3).^2);
    s0 = mb.sigma0*ones(M.nElem,1); s0(M.dom == 2) = mt.sigma0;
    FI = f*s1./s0;                                         % failure index field at P_fail
    c = M.centroid; w = [M.xa - 0.25*M.lambda, M.xb + 0.25*M.lambda]; yl = [-M.A - 1.6, M.A + 1.6]; pad = 0.3;
    sel = sel_window(M.quads, M.nodes, w, yl);
    ax = subplot(1,3,it); hold on; box on; axis equal;
    [X, Y, V] = field_contour(ax, c, M.dom, FI, M.poly, w, yl, 0.6:0.05:1.2);
    contour(ax, X, Y, V, [1 1], 'w-', 'LineWidth', 1.4);          % isoline sigma_1/sigma_0 = 1
    plot(M.poly(:,1), M.poly(:,2), 'k-', 'LineWidth', 1.2);
    p2 = tcd_locus(M.poly, mt.L/2, 2, M.xa, M.xb, M.H, cfg); [~, o2] = sort(p2(:,1));
    p1 = tcd_locus(M.poly, mb.L/2, 1, M.xa, M.xb, M.H, cfg); [~, o1] = sort(p1(:,1));
    plot(p2(o2,1), p2(o2,2), 'k.', 'MarkerSize', 3); plot(p1(o1,1), p1(o1,2), 'k.', 'MarkerSize', 3);
    D = res(k).dom(res(k).gov1_domain);
    plot(D.p1(1), D.p1(2), 'p', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'k', 'MarkerSize', 13);
    caxis([0.6 1.2]); colormap(ax, fe_cmap(12)); axis([w yl]);
    if it == 3, add_colorbar(ax, '\sigma_1/\sigma_0'); end
    panel_label(ax, lt(it), 'x (mm)', 'y (mm)');
end
save_fig600(fg, 'Fig10_failure_index'); save_fig_vector(fg, 'Fig10_failure_index');
