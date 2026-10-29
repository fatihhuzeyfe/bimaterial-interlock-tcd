%% FIG06_FE_HEATMAP  FE contour maps of the first principal stress (MPa) from the FEBio results:
%  row 1 mono-material MONO/MONO, row 2 bi-material TOP/BOT, columns = topologies (scale S).
%  Banded colormap (FE-post-processor style); colour range of each row = 0.80-1.25 sigma_nom.
clear; close all;
here = fileparts(mfilename('fullpath')); addpath(here); root = fileparts(here); addpath(root);
MONO = 'ABS'; TOP = 'PLA'; BOT = 'ABS'; S = 2; nBands = 14;   % <-- settings
cfg = study_config(); topos = cfg.topologies; lt = 'abcdef';
cmap = fe_cmap(nBands);
fg = figure('Color','w','Position',[40 40 1350 720]);
pairs = {MONO, MONO; TOP, BOT};
for row = 1:2
    for it = 1:3
        [M, Sg, sn] = load_case_fields(root, topos{it}, S, pairs{row,1}, pairs{row,2});
        s1 = (Sg(:,1) + Sg(:,2))/2 + sqrt(((Sg(:,1) - Sg(:,2))/2).^2 + Sg(:,3).^2);
        c = M.centroid; w = [M.xa - 0.5*M.lambda, M.xb + 0.5*M.lambda]; yl = [-M.A - 2.0, M.A + 2.0]; pad = 0.3;
        sel = sel_window(M.quads, M.nodes, w, yl);
        ax = subplot(2, 3, (row - 1)*3 + it); hold on; box on; axis equal;
        rng_ = [floor(1.6*sn)/2, ceil(2.5*sn)/2];              % 0.80-1.25 sigma_nom rounded to 0.5 MPa
        nb = round((rng_(2) - rng_(1))/0.25);                    % one band per 0.25 MPa
        field_contour(ax, c, M.dom, s1, M.poly, w, yl, linspace(rng_(1), rng_(2), nb + 1));
        plot(M.poly(:,1), M.poly(:,2), 'k-', 'LineWidth', 1.3);
        colormap(ax, fe_cmap(nb)); axis([w yl]);
        set(ax, 'Layer', 'top');
        if it == 3, cb = add_colorbar(ax, '\sigma_1 (MPa)'); set(cb, 'Ticks', rng_(1):0.5:rng_(2)); end
        yy = ''; if it == 1, yy = 'y (mm)'; end
        panel_label(ax, lt((row - 1)*3 + it), 'x (mm)', yy);
    end
end
save_fig600(fg, 'Fig06_FE_stress'); save_fig_vector(fg, 'Fig06_FE_stress');
