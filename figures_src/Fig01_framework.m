%% FIG1_FRAMEWORK  Multi-scale conceptual framework (macro specimen -> strip model -> profiles).
%  Run from the package root (needs study_config.m, build_mesh.m). Output: figures/Fig1_framework.png
clear; close all;
here = fileparts(mfilename('fullpath')); addpath(here); addpath(fileparts(here));   % figures_src and package root
cfg = study_config();
cTop = [0.957 0.635 0.380]; cBot = [0.557 0.792 0.902]; cGrip = [0.75 0.75 0.75];
fg = figure('Color','w','Position',[40 40 1500 580]);

%% (a) macro-scale specimen (schematic, interface exaggerated)
subplot(1,3,1); hold on; axis equal off;
Wm = 10; Hg = 20; Hgrip = 8;
Pm = dovetail_poly(5, Wm/5, 0.6, 15); xi = Pm(:,1).' - Wm/2; yi = Pm(:,2).';   % schematic, exaggerated
patch([xi, Wm/2, -Wm/2], [yi, Hg, Hg], cTop, 'EdgeColor','none');
patch([xi, Wm/2, -Wm/2], [yi, -Hg, -Hg], cBot, 'EdgeColor','none');
hatch_rect(-Wm/2, Wm/2, 2, Hg, 45, 1.0, cTop*0.75);
hatch_rect(-Wm/2, Wm/2, -Hg, -2, -45, 1.0, cBot*0.75);
plot(xi, yi, 'k-', 'LineWidth', 1.4);
rectangle('Position',[-Wm/2-1.5, Hg, Wm+3, Hgrip], 'FaceColor', cGrip, 'EdgeColor','k');
rectangle('Position',[-Wm/2-1.5, -Hg-Hgrip, Wm+3, Hgrip], 'FaceColor', cGrip, 'EdgeColor','k');
plot([-Wm/2 -Wm/2 Wm/2 Wm/2 -Wm/2], [-Hg Hg Hg -Hg -Hg], 'k-', 'LineWidth', 1);
draw_arrow([0 Hg+Hgrip], [0 Hg+Hgrip+6], 'k', 1.6);  text(0.8, Hg+Hgrip+4.5, 'U', 'FontSize', 11, 'FontAngle', 'italic');
for xs = -6:3:6, plot([xs xs-1.2], [-Hg-Hgrip -Hg-Hgrip-1.5], 'k-'); end
plot([-7 7], [-Hg-Hgrip -Hg-Hgrip], 'k-', 'LineWidth', 1.5);
text(-Wm/2-0.3, 12, 'Top layer', 'HorizontalAlignment','right', 'FontSize', 10);
text(-Wm/2-0.3, -12, 'Substrate', 'HorizontalAlignment','right', 'FontSize', 10);
rectangle('Position',[-Wm/2-0.6, -2.4, Wm+1.2, 4.8], 'EdgeColor','r', 'LineStyle','--', 'LineWidth', 1.3);
axis([-15 15 -34 37]);
panel_label(gca, 'a');

%% (b) meso-scale plane-strain strip model
subplot(1,3,2); hold on; axis equal off;
M = build_mesh('Dovetail', cfg.A0, cfg.lambda0, 0.04, cfg);
P = M.poly; W = M.W; H = 2.2;                                   % display height truncated
patch([P(:,1); W; 0], [P(:,2); H; H], cTop, 'EdgeColor','none');
patch([P(:,1); W; 0], [P(:,2); -H; -H], cBot, 'EdgeColor','none');
plot(P(:,1), P(:,2), 'k-', 'LineWidth', 1.2);
plot([0 W W 0 0], [-H -H H H -H], 'k-');
rectangle('Position',[M.xa, -H, M.xb-M.xa, 2*H], 'EdgeColor',[0.8 0 0], 'LineStyle','--', 'LineWidth', 1.3);
for xs = linspace(0.3, W-0.3, 9)
    patch(xs + [-0.18 0.18 0], -H + [-0.32 -0.32 0], 'w', 'EdgeColor','k');
    draw_arrow([xs H], [xs H+0.9], 'k', 1, 0.35);
end
draw_arrow([W/2 -H-1.5], [W -H-1.5], 'k', 0.8, 0.05); draw_arrow([W/2 -H-1.5], [0 -H-1.5], 'k', 0.8, 0.05);
text(W/2, -H - 1.95, 'W', 'HorizontalAlignment','center', 'FontSize', 10, 'FontAngle','italic');
axis([-0.5 W+0.5 -H-2.4 H+1.8]);
panel_label(gca, 'b');

%% (c) micro-scale profiles and material length scales
subplot(1,3,3); hold on; axis equal off;
topo = cfg.topologies; off = [0 -1.9 -3.8];
for it = 1:3
    Mi = build_mesh(topo{it}, cfg.A0, cfg.lambda0, 0.04, cfg);
    Q = Mi.poly(Mi.poly(:,1) >= Mi.xa - 1e-9 & Mi.poly(:,1) <= Mi.xb + 1e-9, :);
    Q(:,1) = Q(:,1) - Mi.xa; y0 = off(it); hb = 0.65;
    patch([Q(:,1); 2; 0], [Q(:,2) + y0; y0 + hb; y0 + hb], cTop, 'EdgeColor','none');
    patch([Q(:,1); 2; 0], [Q(:,2) + y0; y0 - hb; y0 - hb], cBot, 'EdgeColor','none');
    plot(Q(:,1), Q(:,2) + y0, 'k-', 'LineWidth', 1.4);
    text(-0.15, y0, topo{it}, 'HorizontalAlignment','right', 'FontSize', 9, 'FontWeight','bold');
end
y0 = off(1);   % dimensions on the sinusoid
draw_arrow([1 y0+0.85], [2 y0+0.85], 'k', 0.8, 0.12); draw_arrow([1 y0+0.85], [0 y0+0.85], 'k', 0.8, 0.12);
text(1, y0 + 1.1, '\lambda', 'HorizontalAlignment','center', 'FontSize', 10);
draw_arrow([0.5 y0], [0.5 y0 + cfg.A0], 'r', 0.9, 0.3); text(0.56, y0 + 0.2, 'A', 'Color','r', 'FontSize', 10, 'FontAngle','italic');
y0 = off(3); Md = build_mesh('Dovetail', cfg.A0, cfg.lambda0, 0.04, cfg);
xc = 1 - Md.wb/2; plot([xc xc], [y0 - cfg.A0, y0 + cfg.A0], 'k:');
text(xc - 0.3, y0 + 0.05, '\theta_u', 'FontSize', 10);
% material length scales
yb = -5.3;
bars = [cfg.A0, [cfg.mat.L]/2]; labs = [{'A'}, strcat('L/2 ', {cfg.mat.name})];
cb = [0.2 0.2 0.2; 0.49 0.18 0.56; 0.30 0.75 0.93; 0.85 0.33 0.10];
for b = 1:4
    y = yb - 0.3*b; plot([0 bars(b)], [y y], '-', 'Color', cb(b,:), 'LineWidth', 4);
    text(bars(b) + 0.05, y, sprintf('%s (%.2f mm)', labs{b}, bars(b)), 'FontSize', 9);
end
axis([-1.4 3.3 -6.9 1.6]);
panel_label(gca, 'c');
save_fig600(fg, 'Fig01_framework');

