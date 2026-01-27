# Tsunami Vortex Numerical Modelling

Numerical modelling of tsunami-induced vortex dynamics using vorticity–streamfunction formulations.
This repository implements finite-difference simulations (Arakawa Jacobian, elliptic Poisson solve, explicit time stepping)
with automated grid convergence, parameter sweeps, and computational cost logging. Extensions include spectral methods,
finite-volume formulations, and obstacle/bathymetry experiments.

## Key features
- Finite Difference vorticity–streamfunction solver (Arakawa + Poisson + RK)
- Three run modes: evolution / convergence / sweep
- Automated figure saving with parameter-labelled filenames
- Persistent CSV/MAT logging with timestamps
- Cost metrics: wall time, CPU time, memory (telemetry optional)

## Methods
### Finite Difference (FD)
- Governing model: vorticity transport + Poisson streamfunction coupling
- Spatial discretisation: second-order central differences; conservative Jacobian (Arakawa)
- Elliptic subproblem: sparse discrete Laplacian solve for streamfunction
- Time integration: explicit scheme (e.g., RK)

### Spectral / Finite Volume / Obstacle & Bathymetry
See `docs/roadmap.md` and method notes in `docs/`.

## Repository structure
- `src/` core solvers
- `drivers/` analysis drivers (evolution / convergence / sweep)
- `utilities/` plotting + export utilities
- `Results/` CSV/MAT outputs (generated)
- `Figures/` saved figures (generated)
- `docs/` method notes, convergence definition, cost metrics
- `tests/` sanity/regression checks

## Quickstart (MATLAB)
1. Add paths:
   - Ensure `utilities/` is on the MATLAB path.
2. Run:
   - Evolution mode: generates vorticity evolution figures
   - Convergence mode: searches for converged grid size
   - Sweep mode: parameter studies on converged mesh

(See `drivers/Analysis.m` for configuration.)

## Configuration
Simulation parameters are defined in a `params` struct (e.g., `Nx`, `Ny`, `dt`, `Tfinal`, `nu`, `ic_type`, `snap_times`).
Driver settings (results/figures directories, convergence tolerance, sweep lists) are defined in `settings`.

## Convergence criterion
The convergence criterion is defined in `docs/convergence.md` and is based on vorticity-derived features
(e.g., peak |ω| and/or enstrophy) evaluated across grid refinements. The search uses bracketing and binary refinement.

## Outputs
- CSV: appended results table including parameters, runtime metrics, and extracted features
- Figures: saved to `Figures/<mode>/...` with parameter-labelled filenames
- MAT: saved workspace tables and metadata

## Computational cost and telemetry
Wall time, CPU time, and memory usage are captured in-script. Hardware telemetry (temperature/power) is optional and
documented in `docs/cost_metrics.md`.

## References
- J. N. Kutz, *Data-Driven Modeling & Scientific Computation* (2013)
- Additional references listed in `docs/references.md` (and `MECH0020.bib` if included)

## License
Choose a license (MIT/BSD/GPL) and place it in `LICENSE`.
