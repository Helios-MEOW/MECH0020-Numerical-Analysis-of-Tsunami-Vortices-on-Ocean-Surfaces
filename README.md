# Tsunami Vortex Numerical Modelling

Numerical simulation of tsunami-induced vortex dynamics using vorticity–streamfunction formulations. This repository implements finite-difference solvers with Arakawa Jacobian schemes, elliptic Poisson solvers, and explicit time-stepping, supporting automated convergence studies and parameter exploration.

## Key Features

- **Dual-mode operation**: UI mode (3-tab MATLAB interface with Developer Mode) or Standard mode (command-line)
- **Four FD simulation modes**: Evolution, Convergence, ParameterSweep, Plotting
- **Adaptive convergence agent**: Intelligent mesh refinement using learning-based navigation
- **Run tracking**: Unique run IDs, professional reports, master CSV table
- **User-editable configuration**: Centralized parameter/settings files in `Scripts/Editable/`
- **Grid-based UI layout**: Intuitive editing via `UI_Layout_Config.m` with Developer Mode inspector
- **Organized outputs**: Structured directory tree in `Data/Output/` (gitignored)
- **CI/CD**: GitHub Actions workflow for automated testing and static analysis

## Quick Start

### Prerequisites

- MATLAB R2020b or later
- No toolboxes required (base MATLAB only)
- Operating System: Windows, macOS, or Linux

### Installation

```bash
git clone https://github.com/Helios-MEOW/MECH0020-Numerical-Analysis-of-Tsunami-Vortices-on-Ocean-Surfaces.git
cd MECH0020-Numerical-Analysis-of-Tsunami-Vortices-on-Ocean-Surfaces
```

### Running a Simulation

**Option 1: UI Mode (Interactive)**

Launch MATLAB, navigate to the repository, and run:

```matlab
cd Scripts/Drivers
Analysis
```

A startup dialog appears. Select "UI Mode" to access the 3-tab interface:
- **Tab 1: Configuration** — Method, mode, parameters, initial conditions
- **Tab 2: Live Monitor** — Real-time metrics, progress, terminal output
- **Tab 3: Results & Figures** — Load and visualize previous runs

**Developer Mode (for UI editing):**
- Click **"🔧 Developer Mode"** button in menu bar to enable
- Click any component to inspect its properties (type, parent, Layout.Row/Column)
- Use validation tools to check layout correctness
- Edit layout parameters in `Scripts/UI/UI_Layout_Config.m` only

**Expected output**: Interactive UI opens. Configure and run simulations from Tab 1. Results save to `Data/Output/FD/<Mode>/<run_id>/`.

**Option 2: Standard Mode (Command-line)**

Launch MATLAB, navigate to the repository, and run:

```matlab
cd Scripts/Drivers
Analysis
```

When the startup dialog appears, select "Standard Mode". The script continues in command-line mode with these defaults:
- Method: Finite Difference (FD)
- Mode: Evolution
- IC: Lamb-Oseen vortex
- Grid: 128×128
- Time: dt=0.001, Tfinal=1.0

**Expected output**:
```
MECH0020 TSUNAMI VORTEX SIMULATION - STANDARD MODE
Configuration:
  Method: FD
  Mode: Evolution
  IC: Lamb-Oseen
  Grid: 128x128
...
Output Directory: Data/Output/FD/Evolution/FD_Evol_LambOseen_YYYYMMDD_HHMMSS/
Report: Data/Output/FD/Evolution/.../Reports/Report.txt
```

To customize parameters, edit the values in `Analysis.m` lines 56-74 before running.

## Repository Structure

```
MECH0020-Numerical-Analysis-of-Tsunami-Vortices-on-Ocean-Surfaces/
├── Scripts/
│   ├── Drivers/              # Entry points
│   │   ├── Analysis.m        # Main UI/Standard mode launcher
│   │   └── run_adaptive_convergence.m  # Convergence agent runner
│   ├── Solvers/
│   │   ├── FD/               # Finite difference kernels and modes
│   │   ├── Spectral_Analysis.m
│   │   ├── Finite_Volume_Analysis.m
│   │   └── Variable_Bathymetry_Analysis.m
│   ├── Infrastructure/       # Core utilities
│   │   ├── Builds/           # Configuration builders
│   │   ├── DataRelatedHelpers/ # Data persistence and paths
│   │   ├── Initialisers/     # IC factories and setup
│   │   ├── Runners/          # Mode dispatchers
│   │   └── Utilities/        # Validation, metrics, monitoring
│   ├── Editable/             # User-editable configuration files
│   │   ├── Parameters.m      # Physics and numerics defaults
│   │   └── Settings.m        # Operational settings
│   ├── UI/                   # MATLAB UI components
│   ├── Plotting/             # Visualization functions
│   └── Sustainability/       # Performance monitoring
├── Data/
│   ├── Input/                # Reference data (tracked)
│   └── Output/               # Generated results (gitignored)
├── docs/                     # Documentation
│   ├── 01_ARCHITECTURE/
│   ├── 02_DESIGN/
│   └── 03_NOTEBOOKS/
│       └── Tsunami_Vortex_Analysis_Complete_Guide.ipynb
├── utilities/                # Plotting helpers (optional)
├── tests/                    # Test suite
│   └── Run_All_Tests.m
└── README.md
```

**Key directories**:
- **Drivers**: Main entry points (`Analysis.m`, `run_adaptive_convergence.m`)
- **Solvers/FD/**: Four modes (Evolution, Convergence, ParameterSweep, Plotting)
- **Editable**: Configuration files users should modify
- **Output** (created at runtime): `Data/Output/{Method}/{Mode}/{run_id}/`

## Configuration

User-editable configuration is centralized in `Scripts/Editable/`:

### `Parameters.m` - Physics and Numerics

Key parameters (edit this file to change defaults):
- `nu`: Kinematic viscosity (default: 0.001)
- `Lx`, `Ly`: Domain size (default: 2π × 2π)
- `Nx`, `Ny`: Grid resolution (default: 128 × 128)
- `dt`: Time step (default: 0.001)
- `Tfinal`: Simulation end time (default: 1.0)
- `ic_type`: Initial condition type (default: 'Lamb-Oseen')
- `snap_times`: Times to save snapshots (default: 11 evenly spaced)

### `Settings.m` - Operational Settings

Key settings (edit this file to change defaults):
- `save_figures`: Save plots to disk (default: true)
- `save_data`: Save MAT files (default: true)
- `save_reports`: Generate text reports (default: true)
- `monitor_enabled`: Show live monitor (default: true)
- `monitor_theme`: Monitor color scheme (default: 'dark')
- `append_to_master`: Add run to master table (default: true)
- `animation_enabled`: Generate animations (default: false)

You can also override parameters in your own scripts:
```matlab
Parameters = Default_FD_Parameters();
Parameters.Nx = 256;  % Override grid resolution
Parameters.Tfinal = 5.0;  % Override end time
```

## Adaptive Convergence Agent

The adaptive convergence agent (`run_adaptive_convergence.m`) provides intelligent mesh refinement:

**What it does**:
- Runs preflight simulations to establish convergence patterns
- Adaptively selects mesh resolutions based on observed convergence rates
- Avoids brute-force grid sweeps by learning from intermediate results
- Detects early convergence and stops when tolerance is met
- Logs all decisions and metrics to a convergence trace

**How to run**:

```matlab
cd Scripts/Drivers
run_adaptive_convergence
```

**Expected outputs**:
- Console output showing each iteration's mesh, metrics, and decision logic
- Convergence trace CSV: `Data/Output/Convergence_Study/convergence_trace.csv`
- Preflight figures: `Data/Output/Convergence_Study/preflight/`
- Final recommendation: Converged (Nx, Ny, dt) printed to console

**Runtime**: Typically 5-10 iterations for simple ICs, 10-15 for complex cases (depends on tolerance).

## Outputs and Artifacts

All simulation outputs are saved under `Data/Output/` (gitignored):

**Directory structure**:
```
Data/Output/
└── {Method}/              # e.g., FD
    └── {Mode}/            # e.g., Evolution, Convergence
        └── {run_id}/      # Unique ID: FD_Evol_LambOseen_20260207_143022
            ├── Figures/   # PNG plots
            ├── Data/      # MAT files with full state
            └── Reports/   # Text report with metadata
```

**Run ID format**: `{Method}_{Mode}_{IC}_{YYYYMMDD}_{HHMMSS}`

**Generated files**:
- **Figures**: Vorticity contours, streamlines, vector fields (PNG, 300 DPI)
- **Data**: Full workspace including omega, psi, grid, parameters (MAT)
- **Reports**: Professional text report with run metadata, parameters, metrics, paths

**Master runs table**: `PathBuilder.get_master_table_path()` returns the location of the append-safe CSV tracking all runs.

**What to commit**:
- Source code, configuration files, documentation
- Reference data in `Data/Input/`

**What NOT to commit** (already in `.gitignore`):
- `Data/Output/` - simulation results
- `*.asv` - MATLAB autosaves
- `*.log` - log files
- Test outputs

## Troubleshooting

### Missing path errors
**Symptom**: `Undefined function or variable 'Build_Run_Config'`  
**Cause**: MATLAB path not set up correctly  
**Fix**: Run from `Scripts/Drivers/` directory, or manually add paths as shown in `Analysis.m` lines 14-22

### UI doesn't launch
**Symptom**: UI window doesn't appear after running `Analysis`  
**Cause**: MATLAB App Designer support missing or corrupted UI files  
**Fix**: Select "Standard Mode" from the startup dialog to bypass UI. Check `Scripts/UI/UIController.m` exists.

### Missing output directory
**Symptom**: Error creating output directory  
**Cause**: `Data/Output/` not created automatically  
**Fix**: Directory is created on first run. If error persists, manually create: `mkdir Data/Output`

### Very slow simulations
**Symptom**: Simulation takes hours for small grids  
**Cause**: Likely high resolution or small dt causing many timesteps  
**Fix**: Check `Parameters.dt` and `Parameters.Tfinal`. Reduce `Nx`, `Ny`, or increase `dt` (watch CFL < 1).

### Standard mode vs UI mode confusion
**Symptom**: Unsure which mode is running  
**Cause**: Startup dialog is modal  
**Fix**: The dialog forces a choice. "UI Mode" opens tabs, "Standard Mode" continues script execution in command window.

## Testing

Run the comprehensive test suite to verify installation:

```matlab
cd tests
Run_All_Tests
```

**Expected output**: Summary of passed/failed tests for core infrastructure, solvers, and UI components.

**Static analysis** (check code quality):
```matlab
cd tests
static_analysis
```

**CI/CD**: GitHub Actions workflow automatically runs tests on every push (see `.github/workflows/matlab-tests.yml`).

## Editing the UI Layout (Developer Mode)

The UI uses a **grid-based layout** for intuitive editing. All layout parameters are centralized in `Scripts/UI/UI_Layout_Config.m`.

### How to Edit Layout Safely

1. **Enable Developer Mode:**
   - Launch UI: `app = UIController();`
   - Click menu bar button: **"🔧 Developer Mode: OFF"** → turns ON
   - Inspector panel appears showing component details

2. **Inspect a Component:**
   - Click any UI element (dropdown, button, panel)
   - Inspector displays:
     - Type (e.g., `matlab.ui.control.DropDown`)
     - Parent container
     - `Layout.Row` and `Layout.Column` (grid position)
     - Parent grid dimensions

3. **Edit Layout Config:**
   - Open `Scripts/UI/UI_Layout_Config.m`
   - Find the relevant grid definition (e.g., `cfg.config_tab.left.row_heights`)
   - Modify row/column sizes, spacing, or padding
   - Save the file

4. **Validate Changes:**
   - In Developer Inspector, click **"Validate All Layouts"**
   - Checks for invalid row/col indices, leftover `Position` usage
   - Click **"Dump UI Map to Console"** to see full component tree

5. **Reload UI:**
   - Close UI figure
   - Rerun: `app = UIController();`
   - Verify changes took effect

### Rules for UI Editing

✅ **DO:**
- Edit `UI_Layout_Config.m` only
- Use `Layout.Row` and `Layout.Column` for placement
- Use grid layout row/column sizes (`'fit'`, `'1x'`, `'2x'`, pixels)

❌ **DON'T:**
- Add `Position` properties to components
- Edit layout parameters directly in `UIController.m`
- Change callback function signatures (breaks functionality)

### Adding a New Component

1. Add entry to `cfg.placement` in `UI_Layout_Config.m`:
   ```matlab
   'my_new_button', 'config_left', 3, 1, [1 1];  % row 3, col 1, no span
   ```

2. Create component in appropriate `create_*_tab` method in `UIController.m`:
   ```matlab
   app.handles.my_new_button = uibutton(parent_grid, 'Text', 'My Button');
   app.handles.my_new_button.Layout.Row = 3;
   app.handles.my_new_button.Layout.Column = 1;
   ```

3. Validate with Developer Mode before committing

**Reference:** See [MATLAB uigridlayout documentation](https://www.mathworks.com/help/matlab/ref/matlab.ui.container.gridlayout-properties.html)

## Documentation

Additional documentation:
- [Complete Analysis Guide (Jupyter Notebook)](docs/03_NOTEBOOKS/Tsunami_Vortex_Analysis_Complete_Guide.ipynb)

## License

*License information to be added.*

## Contact

*Contact information to be added.*
