%% FIG2_FE_MODEL  (a) 2.5D plane-strain FE model and boundary conditions, (b) mesh detail
%  at the assessed wavelength, (c) theoretical stress-decay profile and TCD definitions.
clear; close all;
here = fileparts(mfilename('fullpath')); addpath(here); addpath(fileparts(here));   % figures_src and package root
cfg = study_config();
cTop = [0.957 0.635 0.380]; cBot = [0.557 0.792 0.902];
M = build_mesh('Dovetail', cfg.A0, cfg.lambda0, cfg.h_prod, cfg);
fg = figure('Color','w','Position',[40 40 1500 540]);

%% (a) whole model with boundary conditions
subplot(1,3,1); hold on; axis equal off;
P = M.poly; W = M.W; H = M.H;
patch([P(:,1); W; 0], [P(:,2); H; H], cTop, 'EdgeColor','none');
patch([P(:,1); W; 0], [P(:,2); -H; -H], cBot, 'EdgeColor','none');
plot(P(:,1), P(:,2), 'k-', 'LineWidth', 1); plot([0 W W 0 0], [-H -H H H -H], 'k-', 'LineWidth', 1);
for xs = linspace(0.4, W-0.4, 11)
    patch(xs + [-0.25 0.25 0], -H + [-0.45 -0.45 0], 'w', 'EdgeColor','k');
    plot(xs + [-0.3 0.3], -H - 0.55*[1 1], 'k-');
    draw_arrow([xs H], [xs H + 1.2], [0.1 0.1 0.6], 1.1, 0.35);
end
xc = M.nodes(M.centerNode,1); plot(xc, -H, 'ks', 'MarkerFaceColor','k', 'MarkerSize', 6);
text(W/2, H + 1.9, 'U_{ref}', 'HorizontalAlignment','center', 'FontSize', 11, 'Color', [0.1 0.1 0.6]);
rectangle('Position',[M.xa, -1.0, M.xb - M.xa, 2.0], 'EdgeColor','r', 'LineStyle','--', 'LineWidth', 1.3);
panel_label(gca, 'a');

%% (b) mesh detail (shared interface nodes, graded towards corners)
subplot(1,3,2); hold on; axis equal; box on;
win = [M.xa - 0.1, M.xb + 0.1, -1.0, 1.0];
sel = sel_window(M.quads, M.nodes, win(1:2), win(3:4));
for d = 1:2
    s = sel & M.dom == d; col = cBot; if d == 2, col = cTop; end
    patch('Faces', M.quads(s,:), 'Vertices', M.nodes, 'FaceColor', col, 'EdgeColor', [0.25 0.25 0.25], 'LineWidth', 0.15);
end
plot(P(:,1), P(:,2), 'k-', 'LineWidth', 1.6);
axis(win);
panel_label(gca, 'b', 'x (mm)', 'y (mm)');

%% (c) theoretical linear-elastic stress decay and TCD definitions
subplot(1,3,3); hold on; box on; grid on;
a = 5;                                              % semi-crack length in units of L
rL = linspace(1e-3, 3, 600);                        % r / L
s_inf = sqrt(1 - (a/(a + 0.5))^2);                  % PM critical remote stress / sigma0
sy = s_inf*(a + rL)./sqrt(rL.*(2*a + rL));          % Westergaard, sigma_y / sigma0
sK = s_inf*sqrt(a/2)./sqrt(rL);                     % singular (LEFM) term
lm = mean(sy(rL <= 2));
patch([rL(rL<=2) 2 0], [sy(rL<=2) 0 0], [0.90 0.93 1.00], 'EdgeColor','none');
h1 = plot(rL, sy, 'b-', 'LineWidth', 2);
h2 = plot(rL, sK, 'k--', 'LineWidth', 1);
h3 = plot([0 3], [1 1], 'r-', 'LineWidth', 1.2);
h4 = plot(0.5, 1, 'rp', 'MarkerFaceColor','r', 'MarkerSize', 13);
h5 = plot([0 2], lm*[1 1], 'b:', 'LineWidth', 1.5);
plot([0.5 0.5], [0 1], 'r:'); plot([2 2], [0 lm], 'b:');
ylim([0 3]); xlim([0 3]);
legend([h1 h2 h3 h4 h5], {'LE field','Singular term','\sigma_0','PM','LM'}, 'Location','northeast', 'FontSize', 8, 'Box', 'off');
panel_label(gca, 'c', 'r/L', '\sigma_1/\sigma_0');
save_fig600(fg, 'Fig03_FE_model');
