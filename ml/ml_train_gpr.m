%% ML_TRAIN_GPR  Gaussian-process surrogate of the TCD effective stress-concentration factor.
%  Requires: Statistics and Machine Learning Toolbox (fitrgp).
%  Inputs : ml_models/ml_dataset.mat (ml_extract_dataset), optional production results for validation.
%  Outputs: ml_models/ml_gpr_models.mat, figures/FigML*_*.png, figures/Table_ML_*.csv
clear; clc; close all;
root = fileparts(fileparts(mfilename('fullpath'))); addpath(root); addpath(fullfile(root, 'ml'));
cfg0 = study_config(); mldir = fullfile(root, cfg0.ml.outdir);
D = load(fullfile(mldir, 'ml_dataset.mat')); cfg = D.cfg; ml = cfg.ml;
figdir = fig_dir();
seed_rng(ml.seed);
topos = cfg.topologies; nT = numel(topos);
allNames = {'A/\lambda', '\theta_u', '\alpha', '\beta', 'ln(r/A)'};

% ---------- independent validation set (real PLA/ABS/PC production analyses) ----------
V = [];
try
    V = ml_validation_set(root);
    fprintf('Validation set: %d samples from the production analyses\n', numel(V.y));
catch err
    fprintf('No validation set (%s)\n', err.message);
end

gprOpts = {'KernelFunction', 'ardsquaredexponential', 'BasisFunction', 'constant', ...
           'Standardize', true, 'FitMethod', 'sd', 'PredictMethod', 'exact'};
Mdl = cell(1, nT); CV = struct([]); VAL = struct([]); cols = cell(1, nT);
for it = 1:nT
    sel = D.topoId == it;  X = D.X(sel,:);  y = D.y(sel);  g = D.grp(sel);
    cols{it} = [1 3 4 5]; if strcmp(topos{it}, 'Dovetail'), cols{it} = 1:5; end
    X = X(:, cols{it});
    % ----- grouped k-fold cross-validation (all samples of one FE run in the same fold)
    ug = unique(g); ug = ug(randperm(numel(ug))); fold = zeros(size(y));
    for f = 1:ml.kfold, fold(ismember(g, ug(f:ml.kfold:end))) = f; end
    yp = nan(size(y)); ys = yp;
    for f = 1:ml.kfold
        tr = fold ~= f; te = fold == f;
        m = fitrgp(X(tr,:), y(tr), gprOpts{:}, 'ActiveSetSize', min(800, sum(tr)));
        [yp(te), ys(te)] = predict(m, X(te,:));
    end
    CV(it).y = y; CV(it).yp = yp; CV(it).ys = ys; CV(it).metrics = gp_metrics(y, yp, ys);
    % ----- final model on all data
    Mdl{it} = fitrgp(X, y, gprOpts{:}, 'ActiveSetSize', min(800, numel(y)));
    kp = Mdl{it}.KernelInformation.KernelParameters;  ls = kp(1:end-1);
    CV(it).length_scales = ls(:).';  CV(it).importance = (1./ls(:).')/sum(1./ls);
    fprintf('%-10s CV: R2 = %.4f  MAPE(K) = %.3f %%  max = %.2f %%  cov95 = %.2f\n', topos{it}, ...
        CV(it).metrics.R2, CV(it).metrics.MAPE, CV(it).metrics.maxAPE, CV(it).metrics.cov95);
    % ----- validation on the real materials
    if ~isempty(V)
        sv = V.topoId == it;
        if any(sv)
            [vp, vs] = predict(Mdl{it}, V.X(sv, cols{it}));
            VAL(it).y = V.y(sv); VAL(it).yp = vp; VAL(it).ys = vs; VAL(it).label = V.label(sv); %#ok<SAGROW>
            VAL(it).metrics = gp_metrics(V.y(sv), vp, vs);
            fprintf('%-10s VAL: R2 = %.4f  MAPE(K) = %.3f %%  max = %.2f %%  cov95 = %.2f\n', topos{it}, ...
                VAL(it).metrics.R2, VAL(it).metrics.MAPE, VAL(it).metrics.maxAPE, VAL(it).metrics.cov95);
        end
    end
end
save(fullfile(mldir, 'ml_gpr_models.mat'), 'Mdl', 'CV', 'VAL', 'cols', 'topos', 'ml');

% ---------- metrics table ----------
fid = fopen(fullfile(figdir, 'Table_ML_metrics.csv'), 'w');
fprintf(fid, 'topology,set,n,R2,RMSE_lnK,MAPE_K_percent,maxAPE_K_percent,coverage95\n');
for it = 1:nT
    m = CV(it).metrics; fprintf(fid, '%s,CV,%d,%.4f,%.5f,%.4f,%.3f,%.3f\n', topos{it}, m.n, m.R2, m.RMSE, m.MAPE, m.maxAPE, m.cov95);
    if numel(VAL) >= it && ~isempty(VAL(it).y)
        m = VAL(it).metrics; fprintf(fid, '%s,validation,%d,%.4f,%.5f,%.4f,%.3f,%.3f\n', topos{it}, m.n, m.R2, m.RMSE, m.MAPE, m.maxAPE, m.cov95);
    end
end
fclose(fid);

% ---------- Fig. ML1: parity plots ----------
f1 = figure('Color','w','Position',[40 40 1600 440]);
for it = 1:nT
    subplot(1, nT + 1, it); hold on; box on; grid on; axis equal;
    K = exp(CV(it).y); Kp = exp(CV(it).yp);
    plot(K, Kp, '.', 'Color', [0.55 0.55 0.55], 'MarkerSize', 5);
    lg = {'CV'};
    if numel(VAL) >= it && ~isempty(VAL(it).y)
        Kv = exp(VAL(it).y); Kvp = exp(VAL(it).yp);
        errorbar(Kv, Kvp, Kvp.*(1 - exp(-1.96*VAL(it).ys)), Kvp.*(exp(1.96*VAL(it).ys) - 1), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 4);
        lg{end+1} = 'Validation'; %#ok<SAGROW>
    end
    lim = [min([K; Kp])*0.995, max([K; Kp])*1.005];
    plot(lim, lim, 'k-'); plot(lim, lim*1.01, 'k:'); plot(lim, lim*0.99, 'k:');
    xlim(lim); ylim(lim);
    panel_label(gca, char('a' + it - 1), 'K_{FE}', 'K_{GPR}');
    if it == 1, legend(lg, 'Location', 'northwest', 'FontSize', 8, 'Box', 'off'); end
end
% (d) ARD relevance of the inputs
ax = subplot(1, nT + 1, nT + 1); hold on; box on; grid on;
Imp = nan(nT, 5);
for it = 1:nT, Imp(it, cols{it}) = CV(it).importance; end
bar(Imp.'); set(ax, 'XTick', 1:5, 'XTickLabel', allNames);
legend(topos, 'Location', 'northwest', 'FontSize', 8, 'Box', 'off');
panel_label(ax, char('a' + nT), '', 'Relevance');
save_fig600(f1, 'Fig14_GPR_parity_relevance'); save_fig_vector(f1, 'Fig14_GPR_parity_relevance');

% ---------- Fig. ML2: design maps eta(A/(L/2), alpha) and inverse design ----------
xg = logspace(log10(1/max(ml.r_over_A)), log10(1/min(ml.r_over_A)), 80);   % A/(L/2)
ag = linspace(-0.30, 0.30, 61);  nu0 = 0.35;  bfac = (1 - 2*nu0)/(2*(1 - nu0));   % beta = bfac*alpha (equal nu)
[XX, AA] = meshgrid(xg, ag);
f2 = figure('Color','w','Position',[40 40 1400 460]);
fid = fopen(fullfile(figdir, 'Table_ML_inverse_design.csv'), 'w');
fprintf(fid, 'topology,alpha,max_A_over_Lhalf_for_eta_0.95,max_A_over_Lhalf_for_eta_0.98\n');
for it = 1:nT
    th = 0; if strcmp(topos{it}, 'Dovetail'), th = cfg.dovetail_undercut_deg; end
    Xq = [0.15*ones(numel(XX),1), th*ones(numel(XX),1), AA(:), bfac*AA(:), log(1./XX(:))];
    eta = reshape(exp(-predict(Mdl{it}, Xq(:, cols{it}))), size(XX));
    subplot(1, nT, it); hold on; box on;
    contourf(XX, AA, eta, 0.80:0.01:1.02, 'LineColor', 'none'); colormap(fe_cmap(15)); caxis([0.85 1.0]);
    [c2, h2] = contour(XX, AA, eta, [0.95 0.98], 'k-', 'LineWidth', 1.3); clabel(c2, h2, 'FontSize', 8);
    if ~isempty(V)
        sv = V.topoId == it;
        plot(exp(-V.X(sv,5)), V.X(sv,3), 'wo', 'MarkerFaceColor', 'k', 'MarkerSize', 5);
    end
    set(gca, 'XScale', 'log');
    panel_label(gca, char('a' + it - 1), 'A/(L/2)', '\alpha');
    if it == nT, add_colorbar(gca, '\eta', false); end
    for ia = 1:numel(ag)
        fprintf(fid, '%s,%.3f,%.4f,%.4f\n', topos{it}, ag(ia), max_x(xg, eta(ia,:), 0.95), max_x(xg, eta(ia,:), 0.98));
    end
end
fclose(fid);
save_fig600(f2, 'Fig15_design_maps'); save_fig_vector(f2, 'Fig15_design_maps');

disp('ML surrogate trained; see figures/ and ml_models/ml_gpr_models.mat');

function m = gp_metrics(y, yp, ys)
K = exp(y); Kp = exp(yp);
m.n = numel(y);
m.R2 = 1 - sum((y - yp).^2)/sum((y - mean(y)).^2);
m.RMSE = sqrt(mean((y - yp).^2));
m.MAPE = 100*mean(abs(Kp - K)./K);
m.maxAPE = 100*max(abs(Kp - K)./K);
m.cov95 = mean(abs(y - yp) <= 1.96*ys);
end

function x = max_x(xg, eta, target)
% largest A/(L/2) below which eta stays >= target (first crossing from small features)
k = find(eta < target, 1, 'first');
if isempty(k), x = xg(end); elseif k == 1, x = NaN; else
    x = exp(interp1(eta([k-1 k]), log(xg([k-1 k])), target)); end
end
