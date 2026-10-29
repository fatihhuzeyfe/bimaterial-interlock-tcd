function flow_box(xc, yc, w, h, txt, fc, fs, fw)
%FLOW_BOX  Rounded box with centred multi-line text (flowchart helper).
if nargin < 7, fs = 8; end
if nargin < 8, fw = 'normal'; end
rectangle('Position', [xc - w/2, yc - h/2, w, h], 'Curvature', 0.15, 'FaceColor', fc, ...
          'EdgeColor', [0.2 0.2 0.2], 'LineWidth', 1);
text(xc, yc, txt, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
     'FontSize', fs, 'FontWeight', fw);
end
