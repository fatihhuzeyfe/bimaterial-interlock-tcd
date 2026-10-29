# Generated outputs

All results are produced locally by the workflow; nothing is precomputed in this repository. Units: mm, MPa, N/mm (force per unit thickness), degrees.

## Folders created by the workflow

| Folder | Created by | Content |
|---|---|---|
| `febio_models/` | `generate_models` | 120 FEBio input files, meshes (`mesh_*.mat`), case list (`cases.mat`) and, after solving, FEBio logs and stress/reaction files |
| `ml_models/` | `ml/ml_generate_design` | 180 virtual bi-material models for the surrogate and, after extraction, `ml_dataset.csv` |
| `tied_models/` | `gen_tied_comparison` | 8 models with duplicated interface nodes and penalty tied contact |
| `figures/` | figure scripts | PNG (600 dpi), EPS and PDF figures and the result tables listed below |

## `results_table.csv` (from `post_process`)

One row per production or convergence analysis. `_top` refers to the top layer, `_bot` to the substrate.

| Column | Description |
|---|---|
| `case` | analysis identifier (topology, scale, element size, top/bottom material) |
| `topology` | `Sinusoidal`, `Triangle` or `Dovetail` |
| `scale` | self-similar scale *s*; wavelength λ = 2.0*s* mm, amplitude A = 0.3*s* mm |
| `A_mm`, `h_mm` | interface amplitude and element size at the corners |
| `top`, `bottom` | materials of the top layer and the substrate |
| `P_ref_Nmm`, `U_ref_mm` | reaction force and applied displacement of the reference state (0.2% nominal strain) |
| `sigma_nom_MPa` | nominal stress P_ref/W |
| `K_top`, `K_bot` | effective stress-concentration factor σ1,max(L/2)/σ_nom of each constituent |
| `A_over_Lhalf_top`, `A_over_Lhalf_bot` | amplitude divided by half the critical distance |
| `I1_top`, `I1_bot` | failure index (σ1/σ0)² on the L/2 locus at the reference load |
| `Iq_top`, `Iq_bot` | quadratic interaction index at the reference load (comparison only) |
| `governing_s1`, `Pfail_s1_Nmm`, `Ufail_s1_mm`, `eta_s1` | governing constituent, failure load, failure displacement and strength ratio η |
| `governing_quad`, `Pfail_quad_Nmm`, `Ufail_quad_mm` | same quantities with the quadratic index (comparison only) |
| `modemix_top_deg`, `modemix_bot_deg` | loading angle ψ = arctan(abs(τ_t)/σ_n) at the critical point |
| `lin_P`, `lin_S` | linearity check P(0.5U)/P(U) and the corresponding stress ratio (0.5 expected) |
| `convergence_only` | 1 for the additional mesh-convergence analyses |

## `ml_models/ml_dataset.csv` (from `ml/ml_extract_dataset`)

4320 samples from 180 virtual joints (12 distances × 2 constituents per joint).

| Column | Description |
|---|---|
| `run` | analysis number, used for grouped cross-validation |
| `topology` | 1 sinusoidal, 2 triangular, 3 dovetail |
| `domain` | 1 substrate, 2 top layer |
| `A_over_lambda`, `theta_u_deg` | amplitude-to-wavelength ratio and dovetail undercut angle |
| `alpha`, `beta` | plane-strain Dundurs parameters of the assessed constituent |
| `log_r_over_A` | ln of the distance from the interface divided by the amplitude |
| `log_K_local` | ln of σ1,max(r) normalized by the far-field stress of the same analysis (surrogate target) |
| `log_K_global` | ln of σ1,max(r) normalized by the nominal stress P/W |

## Tables in `figures/`

| File | Content |
|---|---|
| `Table_GCI.csv` | three-mesh values, observed order, Richardson extrapolation and grid convergence index |
| `Table_decay_exponents_*.csv` | near-field slopes of the stress decay and K at L/2 |
| `Table_tied_contact.csv` | shared nodes versus tied contact: peak stress, K_L/2, η and its change |
| `Table_ML_metrics.csv` | cross-validation and independent-validation metrics of the surrogate |
| `Table_ML_inverse_design.csv` | admissible A/(L/2) for η ≥ 0.95 and 0.98 as a function of α |
