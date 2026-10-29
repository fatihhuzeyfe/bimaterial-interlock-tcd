%% FIG6_STRESS_FIELDS  Normalised sigma_yy, tau_xy and local loading angle psi around the interface
%  for the three topologies (bi-material pair TOP/BOT, scale S). L/2 loci of both constituents overlaid.
clear; close all;
here = fileparts(mfilename('fullpath')); addpath(here); root = fileparts(here); addpath(root);
TOP = 'PLA'; BOT = 'ABS'; S = 2;                      % <-- choose the pair and scale here
cfg = study_config(); topos = cfg.topologies;
fg = figure('Color','w','Position',[40 40 1350 1050]);
lims = {[0.80 1.20], [-0.08 0.08], [0 5]};   % colour limits (adjust if needed)
rowName = {'\sigma_{yy}/\sigma_{nom}', '\tau_{xy}/\sigma_{nom}', '\psi (\circ)'};
lt = 'abcdefghi'; n = 0;
for row = 1:3
    for it = 1:3
        [M, Sg, sn, cs] = load_case_fields(root, topos{it}, S, TOP, BOT);
        c = M.centroid; w = [M.xa - 0.25*M.lambda, M.xb + 0.25*M.lambda];
        yl = [-M.A - 1.5, M.A + 1.5];
        sel = sel_window(M.quads, M.nodes, w, yl);
        switch row
            case 1, v = Sg(:,2)/sn;
            case 2, v = Sg(:,3)/sn;
            case 3, v = atan2d(abs(Sg(:,3)), max(Sg(:,2), eps));
        end
        n = n + 1; ax = subplot(3, 3, n); hold on; box on; axis equal;
        field_contour(ax, c, M.dom, v, M.poly, w, yl, linspace(lims{row}(1), lims{row}(2), 15));
        plot(M.poly(:,1), M.poly(:,2), 'k-', 'LineWidth', 1.2);
        mt = cfg.mat(strcmp({cfg.mat.name}, TOP)); mb = cfg.mat(strcmp({cfg.mat.name}, BOT));
        p2 = tcd_locus(M.poly, mt.L/2, 2, M.xa, M.xb, M.H, cfg); [~, o] = sort(p2(:,1));
        p1 = tcd_locus(M.poly, mb.L/2, 1, M.xa, M.xb, M.H, cfg); [~, o1] = sort(p1(:,1));
        plot(p2(o,1), p2(o,2), 'k.', 'MarkerSize', 2); plot(p1(o1,1), p1(o1,2), 'k.', 'MarkerSize', 2);
        caxis(lims{row}); axis([w yl]);
        if row == 2, colormap(ax, rb_cmap(14)); else, colormap(ax, fe_cmap(14)); end
        if it == 3, add_colorbar(ax, rowName{row}); end
        panel_label(ax, lt(n), 'x (mm)', 'y (mm)');
    end
end
save_fig600(fg, 'Fig07_stress_fields'); save_fig_vector(fg, 'Fig07_stress_fields');
