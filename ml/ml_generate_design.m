%% ML_GENERATE_DESIGN  Latin-hypercube design of virtual bi-material joints for the GPR surrogate.
%  Inputs per run: topology, A/lambda, theta_u (dovetail), E_top/E_bot, nu_top, nu_bot.
%  Output: <cfg.ml.outdir>/*.feb, mesh_*.mat, ml_cases.mat, run lists.
clear; clc;
root = fileparts(fileparts(mfilename('fullpath'))); addpath(root);
cfg = study_config(); ml = cfg.ml; ml.outdir = fullfile(root, ml.outdir);
rmax = ml.A*max(ml.r_over_A);
cfg.d_fine = rmax + 0.4;  cfg.H_min = max(6, 2*rmax + 1);   % refined band covers all r
if ~exist(ml.outdir, 'dir'), mkdir(ml.outdir); end
seed_rng(ml.seed);
cases = struct([]);
for it = 1:numel(cfg.topologies)
    topo = cfg.topologies{it};
    nd = 4 + strcmp(topo, 'Dovetail');                      % number of design variables
    U = lhs_maximin(ml.n_per_topology, nd, 20);
    for k = 1:ml.n_per_topology
        u = U(k,:);
        Alam = ml.Alam(1) + u(1)*diff(ml.Alam);
        Er   = exp(log(ml.Eratio(1)) + u(2)*diff(log(ml.Eratio)));
        nuT  = ml.nu(1) + u(3)*diff(ml.nu);
        nuB  = ml.nu(1) + u(4)*diff(ml.nu);
        th = 0; if nd == 5, th = ml.theta(1) + u(5)*diff(ml.theta); end
        c = cfg; if th > 0, c.dovetail_undercut_deg = th; end
        lam = ml.A/Alam;
        M = build_mesh(topo, ml.A, lam, cfg.h_prod, c);
        base = sprintf('ML_%s_%03d', topo, k);
        save('-v7', fullfile(ml.outdir, ['mesh_' base '.mat']), 'M');
        mT = struct('name','T','E',Er*ml.E_ref,'nu',nuT); mB = struct('name','B','E',ml.E_ref,'nu',nuB);
        U0 = cfg.eps_ref*2*M.H;
        n = numel(cases) + 1;
        cases(n).base = base; cases(n).topo = topo; cases(n).Alam = Alam; cases(n).theta = th; %#ok<SAGROW>
        cases(n).Eratio = Er; cases(n).nuT = nuT; cases(n).nuB = nuB; cases(n).lambda = lam;
        cases(n).U = U0; cases(n).feb = [base '.feb'];
        cases(n).stressLog = ['S_' base '.txt']; cases(n).reactLog = ['R_' base '.txt'];
        write_feb(fullfile(ml.outdir, cases(n).feb), M, mT, mB, U0, cfg, cases(n).stressLog, cases(n).reactLog);
        fprintf('%-22s A/lam=%.3f th=%4.1f Er=%.2f nuT=%.3f nuB=%.3f nE=%d\n', base, Alam, th, Er, nuT, nuB, M.nElem);
    end
end
save('-v7', fullfile(ml.outdir, 'ml_cases.mat'), 'cases', 'cfg');
copyfile(fullfile(root, 'run_all_febio.bat'), fullfile(ml.outdir, 'run_all_febio.bat'));
fprintf('\n%d ML models written to %s\n', numel(cases), ml.outdir);
