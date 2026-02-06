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
- **Directory Structure**: FD-compliant with organized Data/Output/ tree
- **User-Editable Defaults**: Scripts/Editable/ for easy configuration
- **Comprehensive Testing**: Single master test runner (tests/Run_All_Tests.m)
- **Adaptive Convergence Agent**: Learning-based mesh refinement (not a dumb grid sweep)

## Quick Start

### Prerequisites
- MATLAB R2020b or later
- Required Toolboxes: None (base MATLAB only)
- Operating System: Windows, macOS, Linux

### Installation
```bash
git clone https://github.com/your-org/MECH0020-Numerical-Analysis-of-Tsunami-Vortices-on-Ocean-Surfaces.git
cd MECH0020-Numerical-Analysis-of-Tsunami-Vortices-on-Ocean-Surfaces
```

### Running Your First Simulation

**Option 1: UI Mode (Recommended for beginners)**
```matlab
cd Scripts/Drivers
Analysis  % Opens UI with 3 tabs
```

**Option 2: Standard Mode (Recommended for production)**
```matlab
cd Scripts/Drivers
run('Analysis.m')  % Runs with default settings
```

**Option 3: Adaptive Convergence**
```matlab
cd Scripts/Drivers
run_adaptive_convergence
```

## Operating Modes (MECH0020-Compliant)

### UI Mode - Single MATLAB UI (3 Tabs)
Interactive graphical interface for configuration, execution, and results analysis.

**Launching UI Mode**:
```matlab
cd Scripts/Drivers
Analysis  % A startup dialog appears - select "🖥️ UI Mode"
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
- Colored terminal output on right panel

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
cd Scripts/Drivers
run('Analysis.m')  % Default: run_type = 'standard'
```

**Configuration**:
Edit `Analysis.m` or create custom script:
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
All user-editable configuration is in `Scripts/Config/`:
- **`default_parameters.m`** - Physics and numerics (unified for all methods)
- **`user_settings.m`** - IO, logging, monitoring (mode-aware)
- `Default_FD_Parameters.m` - (Legacy - kept for compatibility)
- `Default_Settings.m` - (Legacy - kept for compatibility)

See `Scripts/Config/README.md` for comprehensive configuration guide.

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
Data/Output/FD/Evolution/<run_id>/
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
Data/Output/FD/Convergence/<study_id>/
├── Figures/
│   ├── Convergence_Plots/
│   └── Final_State_Comparison/
├── Reports/
│   └── Convergence_Report.txt
└── Data/
    ├── convergence_results.mat
    └── mesh_<N>/results.mat (for each mesh size)
```

### 3. ParameterSweep
Automated multi-parameter exploration and sensitivity analysis.

**Purpose**: Systematic parameter space exploration
**Use case**: Sensitivity analysis, response surface mapping
**Computational cost**: VERY HIGH (factorial combinations)

**Usage**:
```matlab
Run_Config = Build_Run_Config('FD', 'ParameterSweep', 'Lamb-Oseen');
Parameters = Default_FD_Parameters();
Parameters.sweep_params = {'nu', 'Gamma'};
Parameters.sweep_values = {[1e-5, 1e-4, 1e-3], [1.0, 2.0, 3.0]};
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

**Output Structure**:
```
Data/Output/FD/ParameterSweep/<sweep_id>/
├── Figures/
│   ├── Response_Surfaces/
│   ├── Heatmaps/
│   └── Individual_Runs/
├── Reports/
│   └── Sweep_Report.txt
└── Data/
    ├── sweep_summary.mat
    └── run_<param_set>/results.mat (for each combination)
```

### 4. Plotting
Results visualization and post-processing from saved data.

**Purpose**: Recreate/customize plots from existing simulation data
**Use case**: Publication-quality figures, comparative visualization
**Computational cost**: MINIMAL (no simulation, only plotting)

**Usage**:
```matlab
Run_Config = Build_Run_Config('FD', 'Plotting', 'Lamb-Oseen');
Settings = Default_Settings();
Settings.data_source = 'Data/Output/FD/Evolution/FD_Evol_LambOseen_20240206_143022/Data/results.mat';
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

**Best for**: Recreate-from-PNG workflow, custom visualizations

## Repository Structure

```
MECH0020-Numerical-Analysis-of-Tsunami-Vortices-on-Ocean-Surfaces/
├── Scripts/
│   ├── Drivers/                      # Entry points and orchestration
│   │   ├── Analysis.m               # Main entry point (UI or Standard mode)
│   │   ├── run_adaptive_convergence.m
│   │   ├── ModeDispatcher.m
│   │   └── run_simulation_with_method.m
│   ├── Methods/                      # Method-specific implementations
│   │   └── FiniteDifference/        # FD solver kernels and modes
│   │       ├── Finite_Difference_Analysis.m
│   │       ├── FD_Evolution_Mode.m
│   │       ├── FD_Convergence_Mode.m
│   │       ├── FD_ParameterSweep_Mode.m
│   │       └── FD_Plotting_Mode.m
│   ├── Config/                       # Configuration (USER-EDITABLE)
│   │   ├── default_parameters.m     # Unified physics/numerics defaults
│   │   ├── user_settings.m          # Unified operational settings
│   │   ├── Default_FD_Parameters.m  # (Legacy - kept for compatibility)
│   │   ├── Default_Settings.m       # (Legacy - kept for compatibility)
│   │   ├── Build_Run_Config.m
│   │   ├── Build_Run_Status.m
│   │   └── validate_simulation_parameters.m
│   ├── IO/                           # Input/output and persistence
│   │   ├── PathBuilder.m
│   │   ├── ResultsPersistence.m
│   │   ├── RunIDGenerator.m
│   │   ├── MasterRunsTable.m
│   │   ├── ReportGenerator.m
│   │   └── initialize_directory_structure.m
│   ├── Grid/                         # Grid generation and initial conditions
│   │   ├── ic_factory.m
│   │   ├── initialise_omega.m
│   │   └── disperse_vortices.m
│   ├── Metrics/                      # Diagnostics and convergence metrics
│   │   ├── MetricsExtractor.m
│   │   └── extract_unified_metrics.m
│   ├── Plotting/                     # Visualization and figure formatting
│   │   ├── Plot_Format.m
│   │   ├── Plot_Saver.m
│   │   ├── Plot_Defaults.m
│   │   ├── Plot_Format_And_Save.m
│   │   ├── Legend_Format.m
│   │   └── create_live_monitor_dashboard.m
│   ├── Utils/                        # Generic utility functions
│   │   ├── HelperUtils.m
│   │   ├── ConsoleUtils.m
│   │   ├── mergestruct.m
│   │   ├── display_function_instructions.m
│   │   └── estimate_data_density.m
│   ├── UI/                           # MATLAB UI components (3-tab interface)
│   │   ├── UIController.m
│   │   ├── MonitorInterface.m
│   │   └── OWL_UtilitiesGuideApp.mlapp
│   ├── Sustainability/               # Performance and energy monitoring
│   │   ├── EnergySustainabilityAnalyzer.m
│   │   ├── HardwareMonitorBridge.m
│   │   ├── iCUEBridge.m
│   │   └── update_live_monitor.m
│   └── Solvers/                      # Other solver implementations
│       ├── Spectral_Analysis.m      # (Future method)
│       ├── Finite_Volume_Analysis.m # (Future method)
│       └── Variable_Bathymetry_Analysis.m
├── Data/
│   ├── Input/                        # Reference data, initial conditions
│   └── Output/                       # Generated results (gitignored)
├── Results/                          # Organized run outputs (gitignored)
│   └── FD/
│       ├── Evolution/
│       ├── Convergence/
│       ├── ParameterSweep/
│       └── Plotting/
├── tests/                            # Test suite
│   ├── Run_All_Tests.m              # Master test runner
│   └── test_*.m                     # Individual test files
├── Docs/
│   └── Extra/                        # Extended documentation
│       ├── 01_ARCHITECTURE/
│       ├── 02_DESIGN/
│       ├── 03_NOTEBOOKS/
│       └── markdown_archive/
└── README.md                         # This file
```

**Key Changes in February 2026 Reorganization:**
- **Focused directories**: Replaced broad "Infrastructure" with specific subdirectories (Config, IO, Grid, Metrics, Utils)
- **Method isolation**: FD solver moved to `Scripts/Methods/FiniteDifference/` for clear separation
- **Unified configuration**: `Scripts/Config/default_parameters.m` and `user_settings.m` are single sources of truth
- **Clean root**: Extra documentation moved to `Docs/Extra/`, keeping only README at root
- **Utilities consolidated**: All plotting utilities now in `Scripts/Plotting/`

## Configuration

### Unified Configuration System (February 2026)

**All user-editable defaults are in `Scripts/Config/`**:

1. **`default_parameters.m`** - Physics and numerics (single source of truth)
2. **`user_settings.m`** - Operational settings (IO, logging, plotting)

**Basic usage:**
```matlab
% Load defaults for your method
params = default_parameters('FD');      % Finite Difference
settings = user_settings('Standard');   % Standard/CLI mode

% Override as needed
params.Nx = 256;
params.Tfinal = 2.0;
settings.save_figures = false;

% Validate before running
validate_simulation_parameters(params, settings);
```

**Method-specific defaults:**
```matlab
params = default_parameters('FD');        % Finite Difference
params = default_parameters('Spectral');  % Spectral method
params = default_parameters('FV');        % Finite Volume
```

**Mode-specific settings:**
```matlab
settings = user_settings('UI');          % UI mode
settings = user_settings('Standard');    % Standard/CLI mode
settings = user_settings('Convergence'); % Convergence study
```

See `Scripts/Config/README.md` for detailed configuration guide.

### UI Mode Configuration
Done through the graphical 3-tab interface - self-explanatory tabs guide you through:
- Tab 1: Method, mode, IC, and parameters
- Tab 2: Live monitoring during execution
- Tab 3: Results browsing and analysis

### Legacy Configuration (Maintained for Compatibility)
If you have existing code using:
```matlab
Parameters = Default_FD_Parameters();
Settings = Default_Settings();
```
This still works! The old files are kept for backward compatibility.

## Convergence Criterion
Convergence uses vorticity-derived features (e.g., peak |ω| or enstrophy) across grid refinements. The adaptive agent uses bracketing and binary refinement inside `Scripts/Drivers/AdaptiveConvergenceAgent.m`.

## Outputs

### Run Artifacts
- **Master Runs Table**: `Data/Output/master_runs.csv` - append-safe tracking of all runs
- **Reports**: Professional text reports with all metadata, parameters, and results
- **Figures**: Saved to `Data/Output/<Method>/<Mode>/<run_id>/Figures/` with parameter-labeled filenames
- **MAT Files**: Full workspace data in `Data/Output/<Method>/<Mode>/<run_id>/Data/`
- **PNG Metadata**: Run IDs embedded in PNG metadata for recreate-from-PNG workflow

### Report Contents
Each run generates a professional report containing:
- Run ID and timestamp
- Method, mode, initial condition
- All parameters (grid, time, physics)
- Computational metrics (wall time, CPU time, memory)
- Scientific metrics (max|ω|, enstrophy, energy)
- File paths and artifact locations
- Git commit hash (if available)
- MATLAB version and OS info

## Computational Cost and Telemetry
Wall time, CPU time, and memory usage are captured automatically. Hardware telemetry (temperature/power) is optional and configured in `Scripts/Editable/Default_Settings.m`.

**Performance Monitoring**:
- Wall clock time (tic/toc)
- CPU time (cputime)
- Peak memory usage
- Energy consumption (optional, requires sensor hardware)
- Carbon intensity estimation (optional, via API)

## Testing

### Running Tests
**Master Test Runner** (recommended):
```matlab
cd tests
Run_All_Tests  % Runs all test suites
```

**Individual Test Cases**:
```matlab
cd tests
Test_Cases  % Run specific test scenarios
```

**Test Coverage**:
- Solver kernels (Arakawa, Poisson, RK)
- Mode dispatcher
- Metrics extraction
- IO and logging
- UI components
- Report generation

## Advanced Features

### Adaptive Convergence Agent
Machine learning-enhanced grid refinement that learns optimal mesh sizes:
```matlab
cd Scripts/Drivers
run_adaptive_convergence
```

**Features**:
- Learns from previous convergence studies
- Predicts optimal mesh density
- Reduces wasted computational effort
- Saves training data for continuous improvement

### Recreate-from-PNG Workflow
Run IDs are embedded in PNG metadata. To recreate a figure:
1. Right-click PNG → Properties → Details → find Run ID
2. Open UI Tab 3 (Results)
3. Enter Run ID → Load data → Regenerate figure with custom styling

### Batch Processing
For large parameter sweeps or production runs:
```matlab
% Create batch script
configs = Generate_Batch_Configs('sweep_params.json');
for i = 1:length(configs)
    [Results{i}, paths{i}] = ModeDispatcher(configs{i}, params, settings);
end
```

## Sustainability and Performance

The repository includes optional energy and carbon tracking:
- **Energy Monitoring**: Hardware sensor integration (Linux: RAPL, macOS: powermetrics)
- **Carbon Intensity**: Grid carbon API integration (optional)
- **Cost Estimation**: Compute hour costing for cloud/HPC environments

Enable in `Scripts/Editable/Default_Settings.m`:
```matlab
Settings.enable_energy_monitoring = true;
Settings.enable_carbon_tracking = true;
Settings.grid_region = 'GB';  % for carbon intensity API
```

Logs saved to `Data/Output/<run_id>/Reports/sustainability_report.txt`

## Troubleshooting

### Common Issues

**Issue**: "Path not found" errors
**Solution**: Run `verify_matlab_paths.sh` to check directory structure

**Issue**: UI doesn't launch
**Solution**: Check MATLAB version (R2020b+), ensure no conflicting UI is open

**Issue**: Convergence not detected
**Solution**: Check mesh_sizes array, ensure sufficient resolution range

**Issue**: Out of memory
**Solution**: Reduce grid size (Nx, Ny) or enable memory profiling in Settings

**Issue**: Results not saving
**Solution**: Check write permissions on Data/Output/, verify disk space

### Debug Mode
Enable verbose logging:
```matlab
Settings.debug_mode = true;
Settings.verbose_logging = true;
```

### Getting Help
1. Check `docs/User_Guide.md` for detailed instructions
2. Review `docs/API_Reference.md` for function signatures
3. Open an issue on GitHub with:
   - MATLAB version (`ver`)
   - Operating system
   - Error message (full stack trace)
   - Minimal reproducible example

## Contributing

### Code Standards
- Follow MATLAB style guide (camelCase for functions, PascalCase for classes)
- Add function headers with purpose, inputs, outputs
- Include unit tests for new features
- Update documentation (README, User Guide, API Reference)
- No fabricated citations - use `[[REF NEEDED: ...]]` placeholders

### Development Workflow
1. Create feature branch: `git checkout -b feature/my-feature`
2. Implement changes following MECH0020 spec (see MECH0020_COPILOT_AGENT_SPEC.md)
3. Run tests: `cd tests && Run_All_Tests`
4. Update docs
5. Commit with descriptive message
6. Push and create pull request

### Architecture Guidelines
- Keep `Analysis.m` thin and method-agnostic
- All solvers run through unified dispatcher
- Separate: configuration vs execution vs kernels vs instrumentation vs visuals
- Generated artifacts isolated from source (gitignored)
- One canonical runs table schema (append-safe)

## Citation

If you use this code in your research, please cite:

```
[[REF NEEDED: Proper citation format for this repository/dissertation]]
```

## License

[[FIGURE PLACEHOLDER: License information (e.g., MIT, GPL, Academic)]]

## References

[[REF NEEDED: Primary references for tsunami vortex dynamics]]
[[REF NEEDED: Navier-Stokes vorticity formulation]]
[[REF NEEDED: Arakawa Jacobian scheme]]
[[REF NEEDED: RK3-SSP time integration]]

## Additional Documentation

Extended documentation is available in `Docs/Extra/`:
- **Architecture**: `Docs/Extra/01_ARCHITECTURE/` - Framework design and OWL patterns
- **Design Decisions**: `Docs/Extra/02_DESIGN/` - UI research and redesign plans
- **Notebooks**: `Docs/Extra/03_NOTEBOOKS/` - Jupyter notebooks and guides
- **Archive**: `Docs/Extra/markdown_archive/` - Historical development documentation
- **Agent Spec**: `Docs/Extra/MECH0020_COPILOT_AGENT_SPEC.md` - Agent instructions
- **Completion Reports**: Various implementation and cleanup summaries

## Contact

[[FIGURE PLACEHOLDER: Contact information or institutional affiliation]]
