function run_febio_all(folder, n_test, febio)
%RUN_FEBIO_ALL  Solves all .feb models of a folder with the FEBio command-line solver.
%   run_febio_all                         % production models (febio_models), all
%   run_febio_all('febio_models', 1)      % test run: first model only
%   run_febio_all('ml_models')            % 180 surrogate-training models
%   run_febio_all('tied_models')          % tied-contact comparison models
%   run_febio_all(folder, n, 'C:\...\febio4.exe')   % explicit solver path
%   Models whose .log already reports normal termination are skipped, so the
%   function can be interrupted and restarted at any time.
if nargin < 1 || isempty(folder), folder = 'febio_models'; end
if nargin < 2 || isempty(n_test), n_test = Inf; end
if nargin < 3, febio = ''; end
% ---- FEBio command-line solver (febio5/febio4/febio3.exe) - NOT FEBioStudio.exe ----
dirs = {'C:\Program Files\FEBioStudio\bin', 'C:\Program Files\FEBio Studio\bin', ...
        'C:\Program Files\FEBioStudio2\bin', 'C:\Program Files\FEBio4\bin', ...
        'C:\Program Files\FEBio3.2\bin', 'C:\Program Files\FEBio3\bin'};
exes = {'febio5.exe', 'febio4.exe', 'febio3.exe'};
for i = 1:numel(dirs)
    for j = 1:numel(exes)
        f = fullfile(dirs{i}, exes{j});
        if isempty(febio) && exist(f, 'file'), febio = f; end
    end
end
for j = 1:numel(exes)
    if isempty(febio)
        if ispc, finder = 'where '; else, finder = 'which '; exes{j} = strrep(exes{j}, '.exe', ''); end
        [st, w] = system([finder exes{j}]);
        if st == 0, febio = strtrim(strtok(w, sprintf('\n'))); end
    end
end
if ~isempty(strfind(lower(febio), 'febiostudio.exe'))
    error('FEBioStudio.exe is the GUI, not the solver. Use febio4.exe / febio5.exe from the same folder.');
end
if isempty(febio) || ~exist(febio, 'file')
    d = dir('C:\Program Files\FEBioStudio\bin\*.exe');
    fprintf('Executables in C:\\Program Files\\FEBioStudio\\bin:\n'); fprintf('   %s\n', d.name);
    error('FEBio solver not found. Pass its path as the third argument, e.g. run_febio_all(''febio_models'', Inf, ''C:\\...\\febio4.exe'').');
end
fprintf('FEBio: %s\n', febio);
t_all = tic;

root = fileparts(mfilename('fullpath')); if ~isabs_path(folder), folder = fullfile(root, folder); end
if exist(folder, 'dir') ~= 7, error('Folder %s not found - run generate_models / ml_generate_design first.', folder); end
here = pwd; cd(folder); c = onCleanup(@() cd(here));
F = dir('*.feb');   % AM_*.feb (production) or ML_*.feb (surrogate)
F = F(1:min(numel(F), n_test)); nOK = 0; bad = {};
for k = 1:numel(F)
    [~, b] = fileparts(F(k).name);
    if isdone([b '.log']), fprintf('[%3d/%3d] already solved: %s\n', k, numel(F), b); continue; end
    t0 = tic;
    [st, out] = system(sprintf('"%s" -i "%s"', febio, F(k).name));
    if isdone([b '.log'])
        nOK = nOK + 1; fprintf('[%3d/%3d] OK  (%5.1f s) %s\n', k, numel(F), toc(t0), b);
    else
        bad{end+1} = b; %#ok<SAGROW>
        fprintf(2, '[%3d/%3d] FAILED %s (exit %d)\n%s\n', k, numel(F), b, st, out(max(1,end-600):end));
    end
end
fprintf('\nFolder: %s\n.feb files found: %d, solved now: %d, failed: %d\n', folder, numel(dir('*.feb')), nOK, numel(bad));
if ~isempty(bad), fprintf('Failed models:\n'); fprintf('  %s\n', bad{:}); end
fprintf('Total time: %.1f min\n', toc(t_all)/60);
end

function tf = isdone(logf)
tf = false;
if exist(logf, 'file'), tf = ~isempty(strfind(fileread(logf), 'N O R M A L')); end
end

function tf = isabs_path(p)
tf = ~isempty(p) && (p(1) == filesep || p(1) == '/' || (numel(p) > 1 && p(2) == ':'));
end
