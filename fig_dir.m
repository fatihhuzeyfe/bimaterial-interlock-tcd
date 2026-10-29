function d = fig_dir()
%FIG_DIR  Absolute path of the package's figures folder (created if missing).
d = fullfile(fileparts(mfilename('fullpath')), 'figures');
if exist(d, 'dir') ~= 7, mkdir(d); end
end
