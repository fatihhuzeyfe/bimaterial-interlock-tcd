function panel_label(ax, letter, xl, yl)
%PANEL_LABEL  Bold axis labels and a "(a)" panel label as the second line of the x-label.
%   The label is part of the axes, so it is never clipped on export.
%   panel_label(ax, 'a', 'r (mm)', '\sigma_1/\sigma_{nom}')   - plot panels
%   panel_label(ax, 'a')                                       - schematic (axis-off) panels
if nargin < 3, xl = ''; end
if nargin < 4, yl = ''; end
set(ax, 'FontSize', 10, 'LineWidth', 0.8);
if isempty(xl) && isempty(yl) && strcmp(get(ax, 'Visible'), 'off')
    set(ax, 'Visible', 'on', 'XColor', 'none', 'YColor', 'none', 'XTick', [], 'YTick', [], 'Color', 'none');
    h = xlabel(ax, ['(' letter ')']); set(h, 'Color', 'k', 'FontWeight', 'normal', 'FontSize', 11);
    return;
end
if isempty(xl), h = xlabel(ax, ['\rm(' letter ')']);
else,           h = xlabel(ax, {['\bf' xl], ['\rm(' letter ')']}); end
set(h, 'FontWeight', 'normal', 'FontSize', 11);
if ~isempty(yl), ylabel(ax, ['\bf' yl], 'FontSize', 11); end
end
