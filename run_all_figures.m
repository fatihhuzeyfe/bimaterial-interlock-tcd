function run_all_figures()
%RUN_ALL_FIGURES  Regenerates every manuscript figure (600 dpi) in the order of the paper.
%  Requirements: results.mat (post_process) and the production FEBio logs.
%  Figs. 14-15 are produced by ml/ml_train_gpr (Statistics and Machine Learning Toolbox).
root = fileparts(mfilename('fullpath'));
src  = fullfile(root, 'figures_src');
addpath(root, src, fullfile(root, 'ml'));
list = {'Fig01_framework','Fig02_workflow','Fig03_FE_model','Fig04_verification','Fig05_TCD_locus', ...
        'Fig06_FE_heatmap','Fig07_stress_fields','Fig08_interface_tractions','Fig09_stress_decay', ...
        'Fig10_failure_index','make_figures','Fig13_scale_fields'};
missing = {};
for k = 1:numel(list)
    f = fullfile(src, [list{k} '.m']); if ~exist(f, 'file'), f = fullfile(root, [list{k} '.m']); end
    if ~exist(f, 'file'), missing{end+1} = list{k}; end %#ok<AGROW>
end
if ~isempty(missing)
    fprintf(2, ['These scripts are missing: %s\nCopy the complete "figures_src" folder of the latest package into\n  %s\n' ...
                '(old files such as fig1_framework.m can be deleted).\n'], strjoin(missing, ', '), src);
end
for k = 1:numel(list)
    fprintf('--- %s\n', list{k});
    f = fullfile(src, [list{k} '.m']); if ~exist(f, 'file'), f = fullfile(root, [list{k} '.m']); end
    if ~exist(f, 'file'), fprintf(2, '    not found: %s\n', f); continue; end
    try, run_isolated(f); catch err, fprintf(2, '    skipped: %s\n', err.message); end
    close all;
end
disp('Figs. 14-15: run ml_train_gpr.');
end

function run_isolated(f)
% runs a figure script (full path) in its own workspace (the scripts start with "clear")
run(f);
end
