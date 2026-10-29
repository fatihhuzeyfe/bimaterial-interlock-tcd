%% EXPORT_PAPER_FIGURES  Copies the figures of the article to
%  figures_paper/Fig1 ... Fig13 (PNG, EPS and PDF). Run run_all_figures and ml_train_gpr first.
root = fileparts(mfilename('fullpath')); src = fullfile(root, 'figures'); dst = fullfile(root, 'figures_paper');
if exist(dst, 'dir') ~= 7, mkdir(dst); end
map = {'Fig01_framework', 'Fig02_workflow', 'Fig04_verification', 'Fig03_FE_model', 'Fig06_FE_stress', ...
       'Fig08_interface_tractions', 'Fig09_stress_decay', 'Fig10_failure_index', 'Fig11_gradients_envelopes', ...
       'Fig12_strength_size', 'Fig13_scale_fields', 'Fig14_GPR_parity_relevance', 'Fig15_design_maps'};
ext = {'.png', '.eps', '.pdf'};
for k = 1:numel(map)
    for e = 1:numel(ext)
        f = fullfile(src, [map{k} ext{e}]);
        if exist(f, 'file') == 2, copyfile(f, fullfile(dst, sprintf('Fig%d%s', k, ext{e}))); end
    end
    fprintf('Fig%d <- %s\n', k, map{k});
end
