function save_fig_vector(fig, name)
%SAVE_FIG_VECTOR  Exports FIG as vector EPS and PDF (editable in CorelDRAW / Illustrator).
%   save_fig_vector(gcf, 'Fig04_verification')  ->  figures/Fig04_verification.eps / .pdf
%   Text stays editable; lines, markers and contour patches become vector objects.
if nargin < 1 || isempty(fig), fig = gcf; end
if nargin < 2, name = 'figure'; end
d = fullfile(fileparts(mfilename('fullpath')), 'figures');
if exist(d, 'dir') ~= 7, mkdir(d); end
f = fullfile(d, name);
set(fig, 'Renderer', 'painters', 'Color', 'w');
if exist('exportgraphics', 'file') == 2 || exist('exportgraphics', 'builtin') == 5     % R2020a+
    exportgraphics(fig, [f '.eps'], 'ContentType', 'vector', 'BackgroundColor', 'white');
    exportgraphics(fig, [f '.pdf'], 'ContentType', 'vector', 'BackgroundColor', 'white');
else                                                                                    % older releases
    set(fig, 'PaperPositionMode', 'auto', 'InvertHardcopy', 'off');
    print(fig, '-depsc', '-painters', [f '.eps']);
    print(fig, '-dpdf',  '-painters', '-bestfit', [f '.pdf']);
end
fprintf('  saved %s.eps and %s.pdf (vector)\n', f, f);
end
