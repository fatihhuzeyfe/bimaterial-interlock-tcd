function cfg = study_config()
%STUDY_CONFIG  Single source of truth for all model, material and TCD parameters.
%   Every number reported in Materials & Methods should be read from here.

%% ---------------- Materials (Table 1) ----------------
% E [MPa], nu [-], sigma0 [MPa] (= sigma_u, Sec. 2.4.1), KIc [MPa*m^0.5]
% All values must come from PRINTED specimens of ONE source per material.
%  ABS : Nabavi-Kivi et al., TAFM 118 (2022) 103223 - printing speed 50 mm/s
%  PC  : Sedighi et al., RPJ 28(2) (2022) 226-235   - raster 45/-45 (LEFM verified)
%  PLA : see switch below
cfg.PLA_source = 'AhmedSusmel2019';   % <-- choose BEFORE generating the models
switch cfg.PLA_source
    case 'AhmedSusmel2019'
        % Ahmed & Susmel, FFEMS 42 (2019) 883-904: E, sigma_UTS, KIc measured on the
        % same 100 %-infill prints; TCD with sigma0 = sigma_UTS validated for AM PLA.
        % nu is not reported there -> 0.37 adopted from Ayatollahi et al. (2020).
        cfg.mat(1) = struct('name','PLA','E',3479,'nu',0.37,'sigma0',42.9,'KIc',3.70);
    case 'Ayatollahi2020'
        % Ayatollahi et al., EFM 237 (2020) 107225, raster 45/-45 printed:
        % E = 1623 MPa, nu = 0.37, elastic-perfectly plastic, sigma_y = 23.6 MPa,
        % Jc = 6815 J/m^2 -> KIc = sqrt(Jc*E/(1-nu^2)) = 3.58 MPa*m^0.5 (plane strain)
        cfg.mat(1) = struct('name','PLA','E',1623,'nu',0.37,'sigma0',23.6,'KIc',3.58);
    case 'original'
        % previous values: E of the printed 45/-45 samples, but sigma_u = 54 MPa and
        % E = 2.34 GPa used for KIc belong to the FILAMENT (Table 1 of that paper) -> inconsistent
        cfg.mat(1) = struct('name','PLA','E',1623,'nu',0.37,'sigma0',54.00,'KIc',3.99);
end
cfg.mat(2) = struct('name','ABS','E',2357,'nu',0.34,'sigma0',32.90,'KIc',2.00);
cfg.mat(3) = struct('name','PC' ,'E',2070,'nu',0.37,'sigma0',42.05,'KIc',3.72);
for k = 1:numel(cfg.mat)
    cfg.mat(k).tau0 = cfg.mat(k).sigma0/sqrt(3);                       % Eq. (1)
    cfg.mat(k).L    = 1e3*(1/pi)*(cfg.mat(k).KIc/cfg.mat(k).sigma0)^2;  % Eq. (2), [mm]
end
Lmax = max([cfg.mat.L]);

%% ---------------- Geometry ----------------
cfg.topologies = {'Sinusoidal','Triangle','Dovetail'};
cfg.lambda0 = 2.0;          % reference wavelength [mm]
cfg.A0      = 0.3;          % reference amplitude  [mm]  (A/lambda = 0.15 for all scales)
cfg.scales  = [0.5 1 2 4];  % self-similar scale factors -> A = 0.15, 0.3, 0.6, 1.2 mm
cfg.dovetail_undercut_deg = 15;  % flank inclination beyond vertical (re-entrant angle)
cfg.n_wave  = 5;            % number of wavelengths modelled (odd); only the central one is assessed
cfg.H_min   = max(5.0, 2*Lmax);  % min. height of each constituent: >= 2L keeps L/2 far from the grips [mm]
cfg.H_over_lambda = 2.5;    % H = max(H_min, 2.5*lambda)
cfg.t       = 0.05;         % out-of-plane thickness of the single element layer [mm]

%% ---------------- Mesh ----------------
cfg.h_prod    = 0.02;           % element size at the interface for production runs [mm]
cfg.h_conv    = [0.04 0.02 0.01];% mesh-convergence levels
cfg.conv_scale = 1;              % scale factor used for the convergence study
cfg.conv_pairs = {'PLA','ABS'; 'ABS','PLA'};   % {top, bottom} pairs used for convergence
cfg.growth    = 1.15;           % element growth ratio away from corners/interface
cfg.hmax_factor = 4;            % max in-plane element size in fine region = 4*h
cfg.hmid_factor = 3;            % element size in the TCD evaluation band = 3*h
cfg.d_fine    = Lmax/2 + 0.4;   % depth of the refined band on each side of the interface [mm]

%% ---------------- Loading ----------------
cfg.eps_ref = 0.002;            % nominal strain at the elastic reference state (0.2 %)
                                % U_ref = eps_ref * 2H (small strain -> neo-Hookean == Hooke)
%% ---------------- TCD evaluation ----------------
cfg.ds_locus  = 0.005;          % sampling step of the L/2 locus [mm]
cfg.corner_deg = 5;             % polyline vertices turning more than this are corners
cfg.path_len  = 2.0;            % length of extracted stress paths [mm]

%% ---------------- Files ----------------
cfg.outdir = 'febio_models';
cfg.feb_version = '4.0';

%% ---------------- Tied-contact comparison (verification of the shared-node approach) ------
cfg.tied.outdir    = 'tied_models';
cfg.tied.topo      = 'Dovetail';
cfg.tied.scales    = [1 2];
cfg.tied.pairs     = {'ABS','ABS'; 'PLA','ABS'};
cfg.tied.penalties = [1e4 1e6];      % 1e4 = value of the original (contact-based) models

%% ---------------- Machine-learning surrogate (Sec. 2.6) ----------------
% Dimensionless design space; linear elasticity is scale-free, so A is fixed and
% the TCD distance enters only through r/A (extracted in post-processing).
cfg.ml.outdir   = 'ml_models';
cfg.ml.n_per_topology = 60;           % LHS samples per topology (180 FE runs)
cfg.ml.A        = 0.3;                % fixed amplitude [mm]
cfg.ml.Alam     = [0.05 0.30];        % A/lambda range
cfg.ml.theta    = [5 25];             % dovetail undercut range [deg]
cfg.ml.Eratio   = [0.5 2.0];          % E_top/E_bottom range (sampled log-uniformly)
cfg.ml.nu       = [0.30 0.40];        % Poisson's ratio range of each constituent
cfg.ml.E_ref    = 2000;               % E of the substrate [MPa] (results depend on the ratio only)
cfg.ml.r_over_A = logspace(log10(0.4), log10(10), 12); % evaluation distances r/A (covers all real cases)
cfg.ml.seed     = 2026;
cfg.ml.kfold    = 5;                  % grouped (by FE run) cross-validation   % '4.0' for febio4.exe (FEBio Studio 2.x/3.x); '3.0' for febio3.exe
end
