# Tsunami Vortex Numerical Modelling

Numerical modelling of tsunami-induced vortex dynamics using vorticity–streamfunction formulations.
This repository implements finite-difference simulations (Arakawa Jacobian, elliptic Poisson solve, explicit time stepping)
with automated grid convergence, parameter sweeps, and computational cost logging. Extensions include spectral methods,
finite-volume formulations, and obstacle/bathymetry experiments.

## Key Features (MECH0020-Compliant Architecture)
- **Single MATLAB UI**: 3-tab interface (Configuration, Live Monitor, Results)
- **Standard Mode**: Command-line driver with dark theme monitor
- **FD Modes**: Evolution, Convergence, ParameterSweep, Plotting (Animation is a setting)
- **Run ID System**: Unique, parseable identifiers with recreate-from-PNG support
- **Professional Reports**: ANSYS/Abaqus-inspired run reports
- **Master Runs Table**: Append-safe CSV tracking all runs
- **Directory Structure**: FD-compliant with organized Results/ tree
- **User-Editable Defaults**: Scripts/Editable/ for easy configuration
- **Comprehensive Testing**: Single master test runner (tests/Run_All_Tests.m)
- **Adaptive Convergence Agent**: Learning-based mesh refinement (not a dumb grid sweep)

## Operating Modes (MECH0020-Compliant)

### UI Mode - Single MATLAB UI (3 Tabs)
Interactive graphical interface for configuration, execution, and results analysis.

**Launching UI Mode**:
```matlab
cd Scripts/Main
Analysis  % or Analysis_New
% A startup dialog appears - select "🖥️ UI Mode"
```

**3 Integrated Tabs**:

**Tab 1 - Configuration** (⚙️):
- Method selection (FD, FFT, FV)
- Mode selection (Evolution, Convergence, ParameterSweep, Plotting)
- Initial condition designer with live preview
- Grid, domain, time, and physics parameters
- Parameter validation and CFL check
- Ready-to-launch checklist

**Tab 2 - Live Monitor** (📊):
- Dark theme live execution monitor
- Real-time metrics (CFL, max|ω|, enstrophy, energy)
- Progress tracking and ETA
- Convergence monitor (when applicable)
- Performance metrics (CPU, memory, wall time)

**Tab 3 - Results & Figures** (📈):
- Browse results by run ID and metadata
- Query/filter by method, mode, IC, date/time
- Load plots, metrics, and reports from selected runs
- Figure gallery with export options
- "Recreate from PNG" workflow support

**Best for**: Interactive research, parameter exploration, teaching

### Standard Mode - Command Line with Dark Monitor
Script-based configuration with live execution monitor.

```matlab
cd Scripts/Main
run('Analysis_New.m')  % Default: run_type = 'standard'
```

**Configuration**:
Edit `Analysis_New.m` or create custom script:
```matlab
Run_Config = Build_Run_Config('FD', 'Evolution', 'Lamb-Oseen');
Parameters = Default_FD_Parameters();  % From Scripts/Editable/
Parameters.Nx = 256;  % Override defaults
Settings = Default_Settings();
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

**Monitor Output** (dark theme, ANSI colors):
- Method, Mode, Initial Condition
- Step, physical time, dt
- Grid info (Nx, Ny, dx, dy)
- Metrics: CFL, max|ω|, enstrophy, energy
- Wall time and progress

**Best for**: Production runs, batch jobs, automated workflows, CI/CD

### Editing Defaults
All user-editable defaults are in `Scripts/Editable/`:
- `Default_FD_Parameters.m` - Physics and numerics
- `Default_Settings.m` - IO, logging, monitoring

No need to search core solvers to change defaults.

## FD Modes (Fixed Set - MECH0020 Spec)

### 1. Evolution
Single time evolution simulation with visualization and analysis.

**Purpose**: Baseline simulation for visualization and validation
**Use case**: Kutz figure recreation, initial parameter exploration
**Computational cost**: LOW (single simulation)

**Usage**:
```matlab
Run_Config = Build_Run_Config('FD', 'Evolution', 'Lamb-Oseen');
Parameters = Default_FD_Parameters();
Settings = Default_Settings();
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

**Output Structure**:
```
Results/FD/Evolution/<run_id>/
├── Figures/
│   ├── Evolution/
│   ├── Contours/
│   ├── Vector/
│   ├── Streamlines/
│   └── Animation/  (if Settings.animation_enabled = true)
├── Reports/
│   └── Report.txt
└── Data/
    └── results.mat
```

### 2. Convergence
Grid convergence study with automatic mesh refinement.

**Purpose**: Multi-resolution convergence analysis
**Use case**: Production-quality mesh generation, error estimation
**Computational cost**: HIGH (multiple simulations)

**Usage**:
```matlab
Run_Config = Build_Run_Config('FD', 'Convergence', 'Gaussian');
Parameters = Default_FD_Parameters();
Parameters.mesh_sizes = [32, 64, 128, 256];
Parameters.convergence_variable = 'max_omega';  % or 'energy', 'enstrophy'
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

**Output Structure**:
```
Results/FD/Convergence/<study_id>/
├── Evolution/
├── MeshContours/
├── MeshGrids/
├── MeshPlots/
├── ConvergenceMetrics/
│   ├── <study_id>__convergence_qoi.png
│   ├── <study_id>__convergence_order.png
│   └── <study_id>__walltime.png
└── Reports/
    └── Report.txt
```

### 3. ParameterSweep
Systematic parameter variation study.

**Purpose**: Sensitivity analysis across parameter space
**Use case**: Understanding IC sensitivity, parameter influence
**Computational cost**: MEDIUM-HIGH (many simulations)

**Usage**:
```matlab
Run_Config = Build_Run_Config('FD', 'ParameterSweep', 'Lamb-Oseen');
Parameters = Default_FD_Parameters();
Parameters.sweep_parameter = 'nu';
Parameters.sweep_values = [0.001, 0.002, 0.004];
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

**Output Structure**:
```
Results/FD/ParameterSweep/<study_id>/
├── nu/
│   └── Figures/
├── Reports/
│   ├── <study_id>__sweep_qoi.png
│   ├── <study_id>__sweep_walltime.png
│   └── Report.txt
└── Data/
    └── sweep_data.mat
```

### 4. Plotting
Standalone plotting/visualization from saved data.

**Purpose**: Regenerate plots without rerunning simulations
**Use case**: "Recreate from PNG" workflow, publication figures
**Computational cost**: NEGLIGIBLE (rendering only)

**Usage**:
```matlab
% Extract run_id from PNG filename
run_id = RunIDGenerator.extract_from_filename('my_figure__contour__t0.5.png');

% Create plotting run
Run_Config = Build_Run_Config('FD', 'Plotting', 'Lamb-Oseen', 'source_run_id', run_id);
Parameters.plot_types = {'contours', 'streamlines', 'evolution'};
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

**Output Structure**:
```
Results/FD/Plotting/
├── contours/
├── streamlines/
└── evolution/
```

**Note**: Animation is a **setting** (`Settings.animation_enabled`), not a mode.

## Repository Structure (MECH0020-Compliant)

```
MECH0020-Numerical-Analysis-of-Tsunami-Vortices-on-Ocean-Surfaces/
├── Scripts/
│   ├── Main/
│   │   ├── Analysis.m              (legacy - backward compatibility)
│   │   └── Analysis_New.m          (thin dispatcher-based driver)
│   ├── Methods/
│   │   ├── Finite_Difference_Analysis.m  (core FD solver)
│   │   ├── FD_Evolution_Mode.m     (orchestrates Evolution mode)
│   │   ├── FD_Convergence_Mode.m   (orchestrates Convergence mode)
│   │   ├── FD_ParameterSweep_Mode.m
│   │   └── FD_Plotting_Mode.m
│   ├── Infrastructure/
│   │   ├── PathBuilder.m           (directory structure creator)
│   │   ├── RunIDGenerator.m        (unique run identifiers)
│   │   ├── ModeDispatcher.m        (routes to mode modules)
│   │   ├── MonitorInterface.m      (live monitoring)
│   │   ├── RunReportGenerator.m    (professional reports)
│   │   ├── MasterRunsTable.m       (CSV master table)
│   │   ├── Build_Run_Config.m      (config builder)
│   │   └── Build_Run_Status.m      (status builder)
│   ├── Editable/                   (USER-EDITABLE DEFAULTS)
│   │   ├── Default_FD_Parameters.m (physics + numerics)
│   │   └── Default_Settings.m      (IO, logging, monitoring)
│   ├── UI/
│   │   └── UIController.m          (MATLAB UI - will be 3-tab version)
│   ├── Visuals/
│   │   └── create_live_monitor_dashboard.m
│   └── Sustainability/
│       └── update_live_monitor.m
├── tests/
│   ├── Run_All_Tests.m             (MASTER TEST RUNNER)
│   ├── Test_Cases.m                (minimal test configs)
│   └── test_results.mat            (generated)
├── Results/                        (GENERATED - gitignored)
│   ├── FD/
│   │   ├── Evolution/<run_id>/
│   │   ├── Convergence/<study_id>/
│   │   ├── ParameterSweep/<study_id>/
│   │   └── Plotting/
│   └── Runs_Table.csv              (master table, all methods/modes)
├── utilities/                      (plotting + export utilities)
├── docs/                           (documentation)
├── .gitignore
├── PROJECT_README.md               (this file)
├── NEW_ARCHITECTURE.md             (architecture guide)
└── MECH0020_COPILOT_AGENT_SPEC.md  (authoritative spec)
```

**Key Principles**:
- Single UI entry point (MATLAB only)
- User-editable defaults in `Scripts/Editable/`
- Mode-specific orchestration in mode modules
- Thin `Analysis.m` (dispatcher only)
- Generated artefacts isolated and gitignored

## Quickstart (MATLAB)

### 1. Setup Paths
```matlab
repo_root = '/path/to/MECH0020-Numerical-Analysis-of-Tsunami-Vortices-on-Ocean-Surfaces';
cd(repo_root);
addpath(genpath('Scripts'));
addpath('tests');
```

### 2. Launch with Mode Selection
```matlab
cd Scripts/Main
Analysis  % or Analysis_New
% A startup dialog appears:
%   - Select "🖥️ UI Mode" for interactive 3-tab interface
%   - Select "📊 Standard Mode" for command-line execution
```

### 3. Standard Mode - Direct Script Usage
```matlab
cd Scripts/Main
run('Analysis_New.m')
% Edit run_type = 'standard' in the file, or use script below
```

Or create a custom script:
```matlab
% Build configuration
Run_Config = Build_Run_Config('FD', 'Evolution', 'Lamb-Oseen');

% Load defaults and override
Parameters = Default_FD_Parameters();
Parameters.Nx = 128;
Parameters.Ny = 128;
Parameters.Tfinal = 1.0;

% Settings
Settings = Default_Settings();
Settings.monitor_enabled = true;
Settings.monitor_theme = 'dark';

% Run simulation
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);

% View results
fprintf('Run ID: %s\n', Results.run_id);
fprintf('Output: %s\n', paths.base);
```

### 3. Run Tests
```matlab
cd tests
Run_All_Tests
```

### 4. Convergence Study
```matlab
Run_Config = Build_Run_Config('FD', 'Convergence', 'Gaussian');
Parameters = Default_FD_Parameters();
Parameters.mesh_sizes = [32, 64, 128];
Parameters.Tfinal = 0.5;  % Shorter for convergence
Settings = Default_Settings();
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

### 5. Parameter Sweep
```matlab
Run_Config = Build_Run_Config('FD', 'ParameterSweep', 'Lamb-Oseen');
Parameters = Default_FD_Parameters();
Parameters.sweep_parameter = 'nu';
Parameters.sweep_values = [0.0005, 0.001, 0.002];
Parameters.Nx = 128;
Parameters.Tfinal = 0.5;
Settings = Default_Settings();
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

### 6. Recreate from PNG
```matlab
% Say you have: Results/FD/Evolution/<run_id>/<run_id>__contour__t0.5.png
run_id = RunIDGenerator.extract_from_filename('my_figure.png');
Run_Config = Build_Run_Config('FD', 'Plotting', 'Lamb-Oseen', ...
    'source_run_id', run_id);
Parameters.plot_types = {'contours', 'streamlines'};
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

## Parameter Configuration

### Using Editable Defaults
All user-editable defaults are in `Scripts/Editable/`:
- `Default_FD_Parameters.m` - Physics and numerics (Nx, Ny, Lx, Ly, nu, dt, Tfinal, delta, IC type)
- `Default_Settings.m` - IO, logging, monitoring options

**Example**:
```matlab
% Edit Scripts/Editable/Default_FD_Parameters.m directly
% Or override in your script:
Parameters = Default_FD_Parameters();
Parameters.Nx = 256;
Parameters.Ny = 256;
Parameters.delta = 2;  % Grid spacing scaling factor
Parameters.nu = 1e-4;  % Viscosity
```

### Standard Mode Configuration (Command-Line)
Simulation parameters are set via struct builders:
- Grid: `Nx`, `Ny`, `Lx`, `Ly`, `delta`
- Time: `dt`, `Tfinal`, `nu`
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

## Run ID System

Every simulation/study gets a unique, parseable run identifier.

**Format**: `<timestamp>_<method>_<mode>_<IC>_<grid>_<dt>_<hash>`

**Example**: `20260206T153042Z_FD_Evolution_LambOseen_g128_dt1e-3_hA1B2`

**Components**:
- `20260206T153042Z` - UTC timestamp (ISO 8601 basic format)
- `FD` - Method (Finite Difference)
- `Evolution` - Mode
- `LambOseen` - Initial condition type
- `g128` - Grid size (128×128)
- `dt1e-3` - Timestep (0.001)
- `hA1B2` - Short hash of full config (uniqueness guarantee)

**Figure Naming**: `<run_id>__<figure_type>__<variant>.png`

Example: `20260206T153042Z_FD_Evolution_LambOseen_g128_dt1e-3_hA1B2__contour__t0.5.png`

**Recreate from PNG**:
```matlab
% Parse run_id from filename
run_id = RunIDGenerator.extract_from_filename('my_figure.png');

% Locate saved config
% Searches: Results/FD/Evolution/<run_id>/Config.mat
%           Results/FD/Convergence/<run_id>/Config.mat
%           Results/FD/ParameterSweep/<run_id>/Config.mat

% Regenerate plots
Run_Config = Build_Run_Config('FD', 'Plotting', 'Lamb-Oseen', 'source_run_id', run_id);
Parameters.plot_types = {'contours', 'streamlines'};
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

## Master Runs Table

Single CSV tracking all runs across methods/modes: `Results/Runs_Table.csv`

**Features**:
- Append-safe (concurrent runs won't corrupt)
- Schema evolution (new columns added automatically)
- Optional Excel export with conditional formatting

**Columns**:
- `run_id` - Unique identifier
- `timestamp` - Run date/time
- `method` - FD, FFT, FV
- `mode` - Evolution, Convergence, etc.
- `ic_type` - Initial condition
- `Nx`, `Ny`, `dt`, `Tfinal`, `nu`, `Lx`, `Ly` - Parameters
- `wall_time_s` - Execution time
- `final_time`, `total_steps` - Results
- `max_omega`, `final_energy`, `final_enstrophy` - Metrics

**Query**:
```matlab
% Get all FD Evolution runs
data = MasterRunsTable.query(struct('method', 'FD', 'mode', 'Evolution'));

% Get convergence studies
data = MasterRunsTable.query(struct('mode', 'Convergence'));
```

**Excel Export** (optional, Windows with Excel installed):
```matlab
MasterRunsTable.export_to_excel();
% Creates Results/Runs_Table.xlsx with conditional formatting
```

## Professional Reports

Each run generates `Report.txt` in the run's `Reports/` directory.

**Contents**:
1. **Header** - Run ID, generation timestamp
2. **System Metadata** - MATLAB version, OS, machine, git commit hash
3. **Run Configuration** - Method, mode, IC, identifiers
4. **Parameters** - Physics and numerics (grouped logically)
5. **Settings** - IO, monitoring, logging flags
6. **Results Summary** - Wall time, metrics, final values
7. **File Manifest** - Output directory paths and file counts

**Example**:
```
═══════════════════════════════════════════════════════════════════
  TSUNAMI VORTEX NUMERICAL SIMULATION - RUN REPORT
═══════════════════════════════════════════════════════════════════

Run ID: 20260206T153042Z_FD_Evolution_LambOseen_g128_dt1e-3_hA1B2
Generated: 06-Feb-2026 15:32:18

───────────────────────────────────────────────────────────────────
  SYSTEM METADATA
───────────────────────────────────────────────────────────────────
MATLAB Version: 9.14 (R2023a)
Operating System: Linux
Git Commit: a1b2c3d

───────────────────────────────────────────────────────────────────
  RUN CONFIGURATION
───────────────────────────────────────────────────────────────────
method              : FD
mode                : Evolution
ic_type             : Lamb-Oseen
run_id              : 20260206T153042Z_FD_Evolution_LambOseen_g128_dt1e-3_hA1B2

───────────────────────────────────────────────────────────────────
  PARAMETERS (Physics & Numerics)
───────────────────────────────────────────────────────────────────

Domain:
  Lx                : 6.28319
  Ly                : 6.28319

Grid:
  Nx                : 128
  Ny                : 128

Time Integration:
  dt                : 0.001
  Tfinal            : 1

Physics:
  nu                : 0.001
  ic_type           : Lamb-Oseen

...
```

## Testing

**Master Test Runner**: `tests/Run_All_Tests.m`

Runs all methods and modes with minimal test cases. Produces pass/fail summary.

```matlab
cd tests
Run_All_Tests

% Output:
% ═══════════════════════════════════════════════════════════════
%   MECH0020 COMPREHENSIVE TEST SUITE
% ═══════════════════════════════════════════════════════════════
% 
% Loading test cases...
%   Found 3 test cases
% 
% ───────────────────────────────────────────────────────────────
%   RUNNING TESTS
% ───────────────────────────────────────────────────────────────
% 
% [1/3] FD_Evolution_LambOseen_32x32
%   ✓ PASSED (2.34 s)
% 
% [2/3] FD_Convergence_Gaussian_16_32
%   ✓ PASSED (3.12 s)
% 
% [3/3] FD_ParameterSweep_nu_2vals
%   ✓ PASSED (4.56 s)
% 
% ═══════════════════════════════════════════════════════════════
%   TEST SUMMARY
% ═══════════════════════════════════════════════════════════════
% 
% Total Tests: 3
% Passed:      3 (100.0%)
% Failed:      0
% 
% Total Wall Time: 10.02 s
% 
% ═══════════════════════════════════════════════════════════════
%   ✓ ALL TESTS PASSED
% ═══════════════════════════════════════════════════════════════
```

**Test Cases**: Defined in `tests/Test_Cases.m`
- Minimal configurations (small grids, short times)
- Fixed seeds for reproducibility
- Covers all FD modes

## Physics and Numerics

### Governing Equations
Vorticity-streamfunction formulation of 2D incompressible Navier-Stokes:

[[REF NEEDED: Navier-Stokes vorticity formulation]]

**Vorticity transport**: ∂ω/∂t + u·∇ω = ν∇²ω

**Poisson equation**: ∇²ψ = -ω

**Velocity recovery**: u = -∂ψ/∂y, v = ∂ψ/∂x

### Numerical Methods

**Finite Difference (FD)**:
- Spatial: 2nd-order central differences
- Advection: Arakawa 3-point scheme (energy-conserving)
- Diffusion: Standard 5-point stencil
- Boundary: Periodic (via circshift)
- Poisson: Sparse matrix solve (A = (1/dx²)⊗Tx + (1/dy²)Ty⊗I)
- Time: RK3-SSP (3rd-order Strong Stability Preserving)
- ODE solver: ode45 (MATLAB adaptive RK)

[[REF NEEDED: Arakawa Jacobian scheme]]

**Future Methods**:
- Spectral (FFT-based)
- Finite Volume (FV)

## Documentation Philosophy (MECH0020 Spec)

Following the specification, this repository:
- **Never fabricates citations** - Use `[[REF NEEDED: description]]` placeholders
- **Never uses ASCII diagrams** - Use `[[FIGURE PLACEHOLDER: description]]` instead
- **Records web sources** in "Sources consulted" bullets (not formal citations)

## Contributing

This is a solo dissertation repository. Changes follow the MECH0020 specification.

## License

[[REF NEEDED: License information]]

## References

[[REF NEEDED: Primary references for tsunami vortex dynamics]]
[[REF NEEDED: Navier-Stokes vorticity formulation]]
[[REF NEEDED: Arakawa Jacobian scheme]]
[[REF NEEDED: RK3-SSP time integration]]

## Contact

[[FIGURE PLACEHOLDER: Contact information or institutional affiliation]]
