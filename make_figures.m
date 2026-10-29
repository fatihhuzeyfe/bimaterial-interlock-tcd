%% MAKE_FIGURES  Fig. 11 and Fig. 12 of the manuscript from results.mat (run post_process first); 600 dpi.
clear; close all;
root = fileparts(mfilename('fullpath')); addpath(root);
S = load(fullfile(root, 'results.mat')); res = S.res; cfg = S.cfg;
topos = cfg.topologies; names = {cfg.mat.name}; prod = ~[res.convOnly];
s_ref = 1;
pairs = {'PLA','ABS'; 'PLA','PC'; 'ABS','PC'};
cols  = [0.49 0.18 0.56; 0.93 0.69 0.13; 0.30 0.75 0.93];
mk = {'o','s','^'}; lt = 'abcdefghi';
pick = @(tp,s,a,b) find(prod & strcmp({res.topo},tp) & abs([res.scale]-s) < 1e-9 & ...
                        strcmp({res.top},a) & strcmp({res.bot},b), 1);

%% Fig. 11 - (a-c) stress gradients in both constituents, (d-f) normalised mixed-mode state at failure
fB = figure('Color','w','Position',[40 40 1250 800]);
for it = 1:3
    ax = subplot(2,3,it); hold on; box on; grid on; hl = []; lg = {};
    for ip = 1:3
        k = pick(topos{it}, s_ref, pairs{ip,1}, pairs{ip,2}); if isempty(k), continue; end
        for d = [2 1]
            D = res(k).dom(d); ls = '-'; if d == 1, ls = '--'; end
            hl(end+1) = plot(D.path.r, D.path.s1/res(k).sig_nom, ls, 'Color', cols(ip,:), 'LineWidth', 1.4); %#ok<SAGROW>
            [~, j] = min(abs(D.path.r - D.r));
            plot(D.path.r(j), D.path.s1(j)/res(k).sig_nom, 'p', 'Color', cols(ip,:), 'MarkerFaceColor', cols(ip,:), 'MarkerSize', 9);
            lg{end+1} = sprintf('%s/%s: %s', pairs{ip,1}, pairs{ip,2}, D.mat); %#ok<SAGROW>
        end
    end
    if it == 3, legend(hl, lg, 'Location', 'northeast', 'FontSize', 8, 'Box', 'off'); end
    panel_label(ax, lt(it), 'r (mm)', '\sigma_1/\sigma_{nom}');
end

th = linspace(0, pi/2, 100);
for it = 1:3
    ax = subplot(2,3,3 + it); hold on; box on; grid on; axis equal; hp = [];
    fill([0 cos(th) 0], [0 sin(th) 0], [0.93 0.93 0.93], 'EdgeColor', 'k', 'LineStyle', '--');
    for ip = 1:3
        k = pick(topos{it}, s_ref, pairs{ip,1}, pairs{ip,2}); if isempty(k), continue; end
        f = 1/sqrt(res(k).I1_gov);
        for d = 1:2
            Lc = res(k).dom(d).locus;
            plot(f*max(Lc.sn,0), f*abs(Lc.tt), '.', 'Color', cols(ip,:), 'MarkerSize', 3);
        end
        D = res(k).dom(res(k).gov1_domain);
        hp(end+1) = plot(f*D.sn, f*abs(D.tt), 'kp', 'MarkerFaceColor', cols(ip,:), 'MarkerSize', 11); %#ok<SAGROW>
    end
    xlim([0 1.1]); ylim([0 1.1]);
    if it == 3, legend(hp, strcat(pairs(:,1), '/', pairs(:,2)), 'Location', 'northeast', 'FontSize', 8, 'Box', 'off'); end
    panel_label(ax, lt(3 + it), '\sigma_n/\sigma_0', '|\tau_t|/\tau_0');
end
save_fig600(fB, 'Fig11_gradients_envelopes');

%% Fig. 12 - (a) nominal failure stress of all combinations, (b) size effect
fD = figure('Color','w','Position',[40 40 1400 480]); ax = subplot(1,2,1); hold on; box on; grid on;
Y = nan(9,3); lab = cell(9,1); s0 = nan(9,1); n = 0;
for iT = 1:3
    for iB = 1:3
        n = n + 1; lab{n} = sprintf('%s/%s', names{iT}, names{iB});
        s0(n) = min(cfg.mat(iT).sigma0, cfg.mat(iB).sigma0);
        for it = 1:3
            k = pick(topos{it}, s_ref, names{iT}, names{iB});
            if ~isempty(k), Y(n,it) = res(k).Pfail1/(res(k).P_ref/res(k).sig_nom); end
        end
    end
end
hb = bar(Y, 0.85, 'EdgeColor', 'none');
bc = [0.00 0.45 0.74; 0.85 0.33 0.10; 0.47 0.67 0.19];
for it = 1:3, set(hb(it), 'FaceColor', bc(it,:)); end
for n = 1:9, hr = plot(n + [-0.42 0.42], s0(n)*[1 1], 'k-', 'LineWidth', 1.8); end
set(ax, 'XTick', 1:9, 'XTickLabel', lab); ylim([0 1.12*max(s0)]); xlim([0.4 9.6]);
legend([hb hr], [topos, {'\sigma_{0,min}'}], 'Location', 'northoutside', 'Orientation', 'horizontal', 'Box', 'off');
set(ax, 'XTickLabelRotation', 30);
panel_label(ax, 'a', 'Top layer / substrate', '\sigma_f (MPa)');

ax = subplot(1,2,2); hold on; box on; grid on; xall = [];
for it = 1:3
    for ip = 1:3
        sel = find(prod & strcmp({res.topo}, topos{it}) & ...
              ((strcmp({res.top},pairs{ip,1}) & strcmp({res.bot},pairs{ip,2})) | ...
               (strcmp({res.top},pairs{ip,2}) & strcmp({res.bot},pairs{ip,1}))));
        if isempty(sel), continue; end
        x = arrayfun(@(r) r.dom(r.gov1_domain).A_over_r, res(sel)); xall = [xall, x]; %#ok<AGROW>
        plot(x, [res(sel).eta1], mk{it}, 'Color', cols(ip,:), 'MarkerFaceColor', cols(ip,:), 'MarkerSize', 7);
    end
end
set(ax, 'XScale', 'log'); xlim([min(xall)/1.25, max(xall)*1.25]); plot(xlim, [1 1], 'k--');
hT = zeros(1,3); hP = zeros(1,3);
for it = 1:3, hT(it) = plot(nan, nan, mk{it}, 'Color', 'k', 'MarkerFaceColor', 'w'); end
for ip = 1:3, hP(ip) = plot(nan, nan, 's', 'Color', cols(ip,:), 'MarkerFaceColor', cols(ip,:)); end
legend([hT hP], [topos, strcat(pairs(:,1).', '/', pairs(:,2).')], 'Location', 'southwest', 'FontSize', 8, 'Box', 'off');
panel_label(ax, 'b', 'A/(L/2)', '\eta');
save_fig600(fD, 'Fig12_strength_size');

disp('Fig11 and Fig12 written (600 dpi)');
