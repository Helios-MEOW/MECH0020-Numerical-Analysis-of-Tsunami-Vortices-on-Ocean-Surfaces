# Tsunami Vortex Numerical Modelling

Numerical modelling of tsunami-induced vortex dynamics using vorticity–streamfunction formulations.
This repository implements finite-difference simulations (Arakawa Jacobian, elliptic Poisson solve, explicit time stepping)
with automated grid convergence, parameter sweeps, and computational cost logging. Extensions include spectral methods,
finite-volume formulations, and obstacle/bathymetry experiments.

## Key features
- **Dual Interface**: Graphical UI or traditional script-based configuration
- Finite Difference vorticity–streamfunction solver (Arakawa + Poisson + RK)
- Three run modes: evolution / convergence / sweep
- Real-time execution and convergence monitoring
- Automated figure saving with parameter-labelled filenames
- Persistent CSV/MAT logging with timestamps
- Cost metrics: wall time, CPU time, memory (telemetry optional)
- Energy monitoring and sustainability tracking

## Operating Modes

### UI Mode (Graphical Interface)
Interactive configuration and monitoring via comprehensive UI:
```matlab
% In Scripts/Main/Analysis.m, set:
use_ui_interface = true;

% Run:
cd Scripts/Main
Analysis
```

**Features**:
- 7-tab interface for complete control
- Real-time parameter validation (CFL, stability)
- Quick start presets (Kutz, convergence, sweep, animation)
- IC designer with live preview
- Embedded monitors (execution and convergence)
- Configuration export/import

**Best for**: Interactive research, parameter exploration, teaching

### Traditional Mode (Script-Based)
Direct parameter configuration in `Analysis.m`:
```matlab
% In Scripts/Main/Analysis.m, set:
use_ui_interface = false;
run_mode = "convergence";  % or "evolution", "sweep", etc.
Parameters.Nx = 128;
% ... (configure all parameters)

% Run:
cd Scripts/Main
Analysis
```

**Features**:
- Parameters set directly in script
- Separate figure windows for monitors
- Batch processing friendly
- Automated workflow support

**Best for**: Production runs, batch jobs, reproducible research

**For detailed UI usage, architecture, and examples**, see [Section 0 of the notebook](Tsunami_Vortex_Analysis_Complete_Guide.ipynb).

## Methods
### Finite Difference (FD)
- Governing model: vorticity transport + Poisson streamfunction coupling
- Spatial discretisation: second-order central differences; conservative Jacobian (Arakawa)
- Elliptic subproblem: sparse discrete Laplacian solve for streamfunction
- Time integration: explicit scheme (RK3-SSP)

## Repository structure
- `Scripts/Main/Analysis.m` main driver (modes: evolution, convergence, sweep, animation, experimentation)
- `Scripts/Methods/Finite_Difference_Analysis.m` solver implementation
- `Scripts/UI/UI_Controller.m` graphical user interface (optional)
- `Scripts/Infrastructure/` core system utilities (directory management)
- `Scripts/Sustainability/` energy monitoring and analysis tools
- `Scripts/Visuals/` live monitoring dashboard
- `utilities/` plotting + export utilities
- `Results/` CSV/MAT outputs (generated)
- `Figures/` saved figures (generated)
- `sensor_logs/` hardware logs (generated, when enabled)

## Quickstart (MATLAB)

### Option 1: UI Mode (Recommended for first-time users)
1. Add script paths:
   ```matlab
   addpath('Scripts/Main', 'Scripts/Methods', 'Scripts/Sustainability', 'Scripts/Visuals', 'Scripts/UI', 'Scripts/Infrastructure');
   ```
2. Launch UI:
   ```matlab
   cd Scripts/Main
   % Set use_ui_interface = true in Analysis.m
   Analysis
   ```
3. Configure simulation in UI tabs and click "🚀 Launch Simulation"

### Option 2: Traditional Mode (Script-based)
1. Add script paths (same as above)
2. Configure parameters in [Scripts/Main/Analysis.m](Scripts/Main/Analysis.m):
   ```matlab
   use_ui_interface = false;  % Traditional mode
   run_mode = "convergence";
   Parameters.Nx = 128;
   % ... (set other parameters)
   ```
3. Run:
   ```matlab
   cd Scripts/Main
   Analysis
   ```

## Configuration

### UI Mode
All configuration done through graphical interface:
- **Tab 1**: Method & Mode selection
- **Tab 2**: Initial Conditions (with preview)
- **Tab 3**: Numerical Parameters (with validation)
- **Tab 4**: Convergence Study settings
- **Tab 5**: Sustainability Tracking
- **Tab 6/7**: Live Monitors (execution and convergence)

### Traditional Mode
Simulation parameters live in the `Parameters` struct inside [Scripts/Main/Analysis.m](Scripts/Main/Analysis.m) (e.g., `Nx`, `Ny`, `dt`, `Tfinal`, `nu`, `ic_type`, `snap_times`).
Driver settings (results/figures directories, convergence tolerance, sweep lists) live in the `settings` struct in the same file.

## Convergence criterion
Convergence uses vorticity-derived features (e.g., peak |ω| or enstrophy) across grid refinements. The search uses bracketing and binary refinement inside [Scripts/Main/Analysis.m](Scripts/Main/Analysis.m).

## Outputs
- CSV: appended results table including parameters, runtime metrics, and extracted features
- Figures: saved to `Figures/<mode>/...` with parameter-labelled filenames
- MAT: saved workspace tables and metadata

## Computational cost and telemetry
Wall time, CPU time, and memory usage are captured in-script. Hardware telemetry (temperature/power) is optional and configured in [Scripts/Main/Analysis.m](Scripts/Main/Analysis.m).

## Notebook (concepts and walkthroughs)
The conceptual discussion and extended walkthrough live in [Tsunami_Vortex_Analysis_Complete_Guide.ipynb](Tsunami_Vortex_Analysis_Complete_Guide.ipynb). This README focuses on **replication** and setup only, so it does not duplicate notebook content.

## Documentation policy
This repository keeps a single Markdown entry point (this README). Historical Markdown files are archived as plain text in [docs/markdown_archive](docs/markdown_archive).

## License
Choose a license (MIT/BSD/GPL) and place it in `LICENSE`.
