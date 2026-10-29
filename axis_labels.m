function axis_labels(ax, xl, yl)
%AXIS_LABELS  Bold axis labels for single-panel figures (no panel letter).
set(ax, 'FontSize', 10, 'LineWidth', 0.8);
if ~isempty(xl), xlabel(ax, ['\bf' xl], 'FontSize', 11); end
if ~isempty(yl), ylabel(ax, ['\bf' yl], 'FontSize', 11); end
end
