function save_fig600(fig, name)
%SAVE_FIG600  Exports FIG to figures/<name>.png at 600 dpi (exportgraphics if available).
f = fullfile(fig_dir(), [name '.png']);
set(fig, 'Color', 'w');
if exist('exportgraphics', 'file') == 2 || exist('exportgraphics', 'builtin') == 5
    exportgraphics(fig, f, 'Resolution', 600, 'BackgroundColor', 'white');
else
    set(fig, 'PaperPositionMode', 'auto', 'InvertHardcopy', 'off');
    print(fig, '-dpng', '-r600', f);
end
fprintf('  saved %s (600 dpi)\n', f);
end
