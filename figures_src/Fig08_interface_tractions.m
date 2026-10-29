%% FIG7_INTERFACE_TRACTIONS  Normal/shear tractions and loading angle along the interface of the
%  assessed wavelength for the three bi-material pairs (scale S). Evaluated at +/- 1.5h from the interface.
clear; close all;
here = fileparts(mfilename('fullpath')); addpath(here); root = fileparts(here); addpath(root);
S = 2;                                                % <-- scale
cfg = study_config(); topos = cfg.topologies;
pairs = {'PLA','ABS'; 'PLA','PC'; 'ABS','PC'}; cols = [0.49 0.18 0.56; 0.93 0.69 0.13; 0.30 0.75 0.93];
fg = figure('Color','w','Position',[40 40 1350 950]); lt = 'abcdefghi';
yn = {'\sigma_n/\sigma_{nom}', '\tau_t/\sigma_{nom}', '\psi (\circ)'};
for it = 1:3
    hl = []; lg = {};
    for ip = 1:3
        [M, Sg, sn] = load_case_fields(root, topos{it}, S, pairs{ip,1}, pairs{ip,2});
        % resample the interface of the assessed wavelength
        P = M.poly; Q = []; T = [];
        for k = 1:size(P,1) - 1
            a = P(k,:); b = P(k+1,:);
            if max(a(1), b(1)) < M.xa || min(a(1), b(1)) > M.xb, continue; end
            m = max(2, ceil(norm(b - a)/(M.h/2))); u = linspace(0, 1, m).'; u = u(1:end-1);
            Q = [Q; a + u*(b - a)]; T = [T; repmat((b - a)/norm(b - a), numel(u), 1)]; %#ok<AGROW>
        end
        keep = Q(:,1) >= M.xa & Q(:,1) <= M.xb; Q = Q(keep,:); T = T(keep,:);
        s = [0; cumsum(sqrt(sum(diff(Q).^2, 2)))]; s = s/s(end);
        N = [-T(:,2), T(:,1)];  del = 1.5*M.h;
        if ip == 1    % analytical tractions of the remote uniaxial stress, Eq. (5): sigma_n = cos^2(phi), tau_t = sin(phi)cos(phi)
            nn = N./sqrt(sum(N.^2, 2)); an = {nn(:,2).^2, nn(:,1).*nn(:,2), atan2d(abs(nn(:,1).*nn(:,2)), max(nn(:,2).^2, eps))};
            for row = 1:3
                subplot(3, 3, (row - 1)*3 + it); hold on;
                ha = plot(s, an{row}, 'k:', 'LineWidth', 1.4);
            end
        end
        for d = [2 1]
            sg = 2*(d == 2) - 1; X = Q + sg*del*N;
            sel = M.dom == d & abs(M.centroid(:,1) - (M.xa + M.xb)/2) < M.lambda & abs(M.centroid(:,2)) < M.A + 0.5;
            V = interp_centroids(M.centroid(sel,:), Sg(sel,:), X);
            snn = V(:,1).*N(:,1).^2 + V(:,2).*N(:,2).^2 + 2*V(:,3).*N(:,1).*N(:,2);
            tt  = (V(:,2) - V(:,1)).*N(:,1).*N(:,2) + V(:,3).*(N(:,1).^2 - N(:,2).^2);
            q = {snn/sn, tt/sn, atan2d(abs(tt), max(snn, eps))};
            ls = '-'; if d == 1, ls = '--'; end
            for row = 1:3
                subplot(3, 3, (row - 1)*3 + it); hold on; box on; grid on;
                h_ = plot(s, q{row}, ls, 'Color', cols(ip,:), 'LineWidth', 1.2);
            end
            mn = pairs{ip, 3 - d};
            hl(end+1) = h_; lg{end+1} = sprintf('%s/%s: %s', pairs{ip,1}, pairs{ip,2}, mn); %#ok<SAGROW>
        end
    end
    for row = 1:3
        ax = subplot(3, 3, (row - 1)*3 + it); robust_ylim(ax); xlim([0 1]);
        if row == 3 && it == 3, legend([hl ha], [lg {'Eq. (5)'}], 'Location', 'best', 'FontSize', 7, 'Box', 'off'); end
        yy = ''; if it == 1, yy = yn{row}; end
        panel_label(ax, lt((row - 1)*3 + it), 's/S', yy);
    end
end
save_fig600(fg, 'Fig08_interface_tractions');
