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

### Starting the Application
When you run `Analysis.m` with `use_ui_interface = true`, a startup dialog appears:

```
┌─────────────────────────────────────┐
│  Choose Simulation Interface        │
│                                     │
│  How would you like to run?         │
│                                     │
│ [🖥️ UI Mode] [📊 Traditional Mode]  │
└─────────────────────────────────────┘
```

Choose based on your workflow:

### UI Mode (Graphical Interface)
Click **🖥️ UI Mode** in startup dialog for interactive configuration:

```matlab
% In Scripts/Main/Analysis.m, set:
use_ui_interface = true;

% Run:
cd Scripts/Main
Analysis

% A dialog appears → Click "🖥️ UI Mode"
% Full 9-tab interface launches
```

**9 Interactive Tabs**:
1. Method & Mode - Select algorithm and run type
2. Initial Conditions - Configure vortex starting state
3. Numerical Parameters - Grid, time, domain settings
4. Convergence Study - Mesh refinement controls
5. Sustainability - Energy/performance monitoring
6. Execution Monitor - Live CPU/memory/progress display
7. Convergence Monitor - Error decay tracking
8. Terminal Output - Console output capture
9. Figures - Generated plot gallery and export

**Features**:
- Real-time parameter validation (CFL, stability)
- Quick start presets (Kutz, Convergence Study)
- IC designer with live preview
- Embedded monitors (execution and convergence)
- Configuration export/import (JSON/MAT)
- Terminal log capture with timestamps
- Figure save/export

**Best for**: Interactive research, parameter exploration, teaching

### Traditional Mode (Script-Based)
Click **📊 Traditional Mode** in startup dialog for script-based configuration:

```matlab
% In Scripts/Main/Analysis.m, set:
use_ui_interface = true;  % Startup dialog still appears

% Run:
cd Scripts/Main
Analysis

% A dialog appears → Click "📊 Traditional Mode"
% OR in Analysis.m, set:
use_ui_interface = false;

% Configure parameters in script:
Parameters.Nx = 128;
Parameters.Ny = 128;
Parameters.dt = 0.001;
% ... (configure all parameters)
```

**Configuration** (edit in Analysis.m):
- Numerical grid: Nx, Ny, Lx, Ly
- Time integration: dt, t_final, viscosity
- Run mode: "evolution", "convergence", "sweep", "animation", "experimentation"
- Numerical method: "finite_difference", "finite_volume", "spectral"
- Initial condition type and parameters

**Features**:
- Separate figure windows for monitoring
- Batch processing capable
- Automated workflows
- Scriptable parameter sweeps

**Best for**: Batch processing, parameter sweeps, automated workflows

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

### Running the Application
1. Add script paths:
   ```matlab
   addpath('Scripts/Main', 'Scripts/Methods', 'Scripts/Sustainability', 'Scripts/Visuals', 'Scripts/UI', 'Scripts/Infrastructure');
   ```

2. Launch Analysis:
   ```matlab
   cd Scripts/Main
   % Set use_ui_interface = true in Analysis.m (recommended)
   Analysis
   ```

3. **A startup dialog appears** - Choose one:
   - **🖥️ UI Mode** (Recommended for first-time users)
     - Full graphical interface with 9 tabs
     - Parameter validation and quick presets
     - Live monitoring and figure export
   - **📊 Traditional Mode** (Script-based)
     - Edit parameters directly in Analysis.m
     - Separate figure windows
     - Best for batch processing

### Option 1: UI Mode Workflow
1. Click **🖥️ UI Mode** in startup dialog
2. Configure simulation across 9 tabs:
   - **Tab 1**: Select method (FD/FV/Spectral) and mode (evolution/convergence/sweep/...)
   - **Tab 2**: Configure initial condition (Kutz preset available)
   - **Tab 3**: Set grid (Nx, Ny), time (dt, T), domain (Lx, Ly)
   - **Tabs 4-5**: Convergence and sustainability settings (optional)
3. Click **🚀 Launch Simulation**
4. Monitor execution in **Tab 8** (Terminal Output)
5. View results in **Tab 9** (Figures) and Results/ folder

### Option 2: Traditional Mode Workflow
1. Click **📊 Traditional Mode** in startup dialog (or set `use_ui_interface = false`)
2. Edit parameters in [Scripts/Main/Analysis.m](Scripts/Main/Analysis.m):
   ```matlab
   run_mode = "convergence";        % evolution, convergence, sweep, animation
   Parameters.Nx = 128;             % Grid points X
   Parameters.Ny = 128;             % Grid points Y
   Parameters.dt = 0.001;           % Timestep
   Parameters.t_final = 10.0;       % Final time
   Parameters.nu = 1e-4;            % Viscosity
   % ... (see Analysis.m for all options)
   ```
3. Run: `Analysis`
4. Monitor via separate figure windows (execution and convergence monitors)

## Configuration

### UI Mode Configuration
Done through the graphical interface - all 9 tabs are self-explanatory:

| Tab | Purpose |
|-----|---------|
| 1 | Method & Mode - Algorithm selection |
| 2 | Initial Conditions - Vortex config + preview |
| 3 | Parameters - Grid, time, domain |
| 4 | Convergence - Mesh refinement settings |
| 5 | Sustainability - Performance monitoring |
| 6 | Execution Monitor - Live CPU/memory/progress |
| 7 | Convergence Monitor - Error decay tracking |
| 8 | Terminal Output - Console logs + export |
| 9 | Figures - Gallery + save/export tools |

### Traditional Mode Configuration
Simulation parameters in the `Parameters` struct, driver settings in the `settings` struct in [Scripts/Main/Analysis.m](Scripts/Main/Analysis.m):
- Grid: `Nx`, `Ny`, `Lx`, `Ly`
- Time: `dt`, `t_final`, `nu`
- Physics: `ic_type`, `ic_coeff1`, `ic_coeff2`
- Output: `snap_times`, `figure_dir`, `results_dir`

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
