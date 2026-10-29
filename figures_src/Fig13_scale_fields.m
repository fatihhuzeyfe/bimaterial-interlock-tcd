%% FIG13_SCALE_FIELDS  Normalised sigma_1/sigma_nom fields in x/A, y/A coordinates for the four
%  self-similar scales (columns) and the three topologies (rows); L/2 loci shrink as A grows.
clear; close all;
here = fileparts(mfilename('fullpath')); addpath(here); root = fileparts(here); addpath(root);
TOP = 'PLA'; BOT = 'ABS';                              % <-- pair
cfg = study_config(); topos = cfg.topologies; sc = cfg.scales;
mt = cfg.mat(strcmp({cfg.mat.name}, TOP)); mb = cfg.mat(strcmp({cfg.mat.name}, BOT));
fg = figure('Color','w','Position',[40 40 1400 900]); n = 0; lt = 'abcdefghijkl';
for it = 1:3
    for is = 1:numel(sc)
        [M, Sg, sn] = load_case_fields(root, topos{it}, sc(is), TOP, BOT);
        s1 = (Sg(:,1) + Sg(:,2))/2 + sqrt(((Sg(:,1) - Sg(:,2))/2).^2 + Sg(:,3).^2);
        xc = (M.xa + M.xb)/2; A = M.A;
        Vn = [(M.nodes(:,1) - xc)/A, M.nodes(:,2)/A];
        c = [(M.centroid(:,1) - xc)/A, M.centroid(:,2)/A];
        win = [-4.5 4.5 -4.5 4.5]; pad = 0.5;
        sel = sel_window(M.quads, Vn, win(1:2), win(3:4));
        n = n + 1; ax = subplot(3, numel(sc), n); hold on; box on; axis equal;
        Pn = [(M.poly(:,1) - xc)/A, M.poly(:,2)/A];
        field_contour(ax, c, M.dom, s1/sn, Pn, win(1:2), win(3:4), 0.9:0.025:1.15);
        plot((M.poly(:,1) - xc)/A, M.poly(:,2)/A, 'k-', 'LineWidth', 1.1);
        p2 = tcd_locus(M.poly, mt.L/2, 2, M.xa, M.xb, M.H, cfg); [~, o2] = sort(p2(:,1));
        p1 = tcd_locus(M.poly, mb.L/2, 1, M.xa, M.xb, M.H, cfg); [~, o1] = sort(p1(:,1));
        plot((p2(o2,1) - xc)/A, p2(o2,2)/A, 'k.', 'MarkerSize', 3); plot((p1(o1,1) - xc)/A, p1(o1,2)/A, 'k.', 'MarkerSize', 3);
        caxis([0.9 1.15]); colormap(ax, fe_cmap(10)); axis(win);
        if is == numel(sc), add_colorbar(ax, '\sigma_1/\sigma_{nom}'); end
        yy = ''; if is == 1, yy = 'y/A'; end
        panel_label(ax, lt(n), 'x/A', yy);
    end
end
save_fig600(fg, 'Fig13_scale_fields'); save_fig_vector(fg, 'Fig13_scale_fields');
