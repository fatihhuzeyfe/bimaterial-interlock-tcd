function [Sg, sig_nom, P] = read_case_stress(M, folder, stressLog, reactLog, t)
%READ_CASE_STRESS  Element stresses (t = 1) mapped to quads, nominal stress, reaction per unit thickness.
Rb = read_febio_log(fullfile(folder, reactLog)); Sb = read_febio_log(fullfile(folder, stressLog));
[~, i1] = max([Rb.time]); [~, j1] = max([Sb.time]);
P = abs(sum(Rb(i1).data(:,2)))/t; sig_nom = P/M.W;
Sg = nan(M.nElem, 3); Sg(M.elemOrder(Sb(j1).data(:,1)), :) = Sb(j1).data(:,2:4);
end
