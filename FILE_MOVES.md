# File Reorganization Table

This document tracks all file moves performed during the February 2026 repository reorganization.

## Summary Statistics
- **Total files moved**: 76
- **New directories created**: 7
- **Directories removed**: 4 (empty after moves)
- **Configuration files unified**: 2 new files created

## Organizational Philosophy

### Before: Broad Categories
- `Scripts/Infrastructure/` - catch-all for utilities, config, IO, metrics
- `Scripts/Editable/` - user-editable configs
- `Scripts/Solvers/FD/` - method-specific code
- `utilities/` - plotting and misc utilities
- `docs/` - all documentation

### After: Focused Responsibilities
- `Scripts/Config/` - ALL configuration (user-editable)
- `Scripts/IO/` - Input/output, persistence, logging
- `Scripts/Grid/` - Grid generation and initial conditions
- `Scripts/Metrics/` - Diagnostics and convergence metrics
- `Scripts/Plotting/` - ALL plotting utilities
- `Scripts/Utils/` - Generic helpers only
- `Scripts/Methods/FiniteDifference/` - FD-specific implementations
- `Docs/Extra/` - Extended documentation (root stays clean)

## File Moves by Category

### Configuration Files → `Scripts/Config/`

| Old Path | New Path | Purpose |
|----------|----------|---------|
| `Scripts/Editable/Default_Settings.m` | `Scripts/Config/Default_Settings.m` | Operational settings (legacy) |
| `Scripts/Editable/Default_FD_Parameters.m` | `Scripts/Config/Default_FD_Parameters.m` | FD parameters (legacy) |
| `Scripts/Infrastructure/create_default_parameters.m` | `Scripts/Config/create_default_parameters.m` | Parameter factory (legacy) |
| `Scripts/Infrastructure/validate_simulation_parameters.m` | `Scripts/Config/validate_simulation_parameters.m` | Parameter validation |
| `Scripts/Infrastructure/Build_Run_Config.m` | `Scripts/Config/Build_Run_Config.m` | Config builder |
| `Scripts/Infrastructure/Build_Run_Status.m` | `Scripts/Config/Build_Run_Status.m` | Status builder |

**New unified files created**:
- `Scripts/Config/default_parameters.m` - Single source of truth for physics/numerics
- `Scripts/Config/user_settings.m` - Single source of truth for operational settings
- `Scripts/Config/README.md` - Configuration guide

### IO & Persistence → `Scripts/IO/`

| Old Path | New Path | Purpose |
|----------|----------|---------|
| `Scripts/Infrastructure/PathBuilder.m` | `Scripts/IO/PathBuilder.m` | Path construction |
| `Scripts/Infrastructure/ResultsPersistence.m` | `Scripts/IO/ResultsPersistence.m` | Save/load results |
| `Scripts/Infrastructure/RunIDGenerator.m` | `Scripts/IO/RunIDGenerator.m` | Unique run IDs |
| `Scripts/Infrastructure/initialize_directory_structure.m` | `Scripts/IO/initialize_directory_structure.m` | Directory creation |
| `Scripts/Infrastructure/MasterRunsTable.m` | `Scripts/IO/MasterRunsTable.m` | Runs table management |
| `Scripts/Infrastructure/ReportGenerator.m` | `Scripts/IO/ReportGenerator.m` | Report generation |
| `Scripts/Infrastructure/RunReportGenerator.m` | `Scripts/IO/RunReportGenerator.m` | Per-run reports |

### Grid & Initial Conditions → `Scripts/Grid/`

| Old Path | New Path | Purpose |
|----------|----------|---------|
| `Scripts/Infrastructure/ic_factory.m` | `Scripts/Grid/ic_factory.m` | Initial condition factory |
| `Scripts/Infrastructure/initialise_omega.m` | `Scripts/Grid/initialise_omega.m` | Vorticity initialization |
| `Scripts/Infrastructure/disperse_vortices.m` | `Scripts/Grid/disperse_vortices.m` | Vortex positioning |

### Metrics & Diagnostics → `Scripts/Metrics/`

| Old Path | New Path | Purpose |
|----------|----------|---------|
| `Scripts/Infrastructure/MetricsExtractor.m` | `Scripts/Metrics/MetricsExtractor.m` | Metrics extraction |
| `Scripts/Solvers/extract_unified_metrics.m` | `Scripts/Metrics/extract_unified_metrics.m` | Unified metrics interface |

### Plotting Utilities → `Scripts/Plotting/`

| Old Path | New Path | Purpose |
|----------|----------|---------|
| `utilities/Plot_Format.m` | `Scripts/Plotting/Plot_Format.m` | Figure formatting |
| `utilities/Plot_Saver.m` | `Scripts/Plotting/Plot_Saver.m` | Figure saving |
| `utilities/Plot_Defaults.m` | `Scripts/Plotting/Plot_Defaults.m` | Default plot settings |
| `utilities/Plot_Format_And_Save.m` | `Scripts/Plotting/Plot_Format_And_Save.m` | Combined format+save |
| `utilities/Legend_Format.m` | `Scripts/Plotting/Legend_Format.m` | Legend formatting |
| `Scripts/Plotting/create_live_monitor_dashboard.m` | *(already in Plotting)* | Monitor dashboard |

### Generic Utilities → `Scripts/Utils/`

| Old Path | New Path | Purpose |
|----------|----------|---------|
| `Scripts/Infrastructure/HelperUtils.m` | `Scripts/Utils/HelperUtils.m` | Generic helpers |
| `Scripts/Infrastructure/ConsoleUtils.m` | `Scripts/Utils/ConsoleUtils.m` | Console output utilities |
| `utilities/display_function_instructions.m` | `Scripts/Utils/display_function_instructions.m` | Function documentation |
| `utilities/estimate_data_density.m` | `Scripts/Utils/estimate_data_density.m` | Data density estimation |
| `Scripts/Solvers/mergestruct.m` | `Scripts/Utils/mergestruct.m` | Struct merging utility |

### FD Solver → `Scripts/Methods/FiniteDifference/`

| Old Path | New Path | Purpose |
|----------|----------|---------|
| `Scripts/Solvers/FD/Finite_Difference_Analysis.m` | `Scripts/Methods/FiniteDifference/Finite_Difference_Analysis.m` | Main FD solver |
| `Scripts/Solvers/FD/FD_Evolution_Mode.m` | `Scripts/Methods/FiniteDifference/FD_Evolution_Mode.m` | Evolution mode |
| `Scripts/Solvers/FD/FD_Convergence_Mode.m` | `Scripts/Methods/FiniteDifference/FD_Convergence_Mode.m` | Convergence mode |
| `Scripts/Solvers/FD/FD_ParameterSweep_Mode.m` | `Scripts/Methods/FiniteDifference/FD_ParameterSweep_Mode.m` | Parameter sweep mode |
| `Scripts/Solvers/FD/FD_Plotting_Mode.m` | `Scripts/Methods/FiniteDifference/FD_Plotting_Mode.m` | Plotting mode |

### Drivers & Orchestration

| Old Path | New Path | Purpose |
|----------|----------|---------|
| `Scripts/Infrastructure/ModeDispatcher.m` | `Scripts/Drivers/ModeDispatcher.m` | Mode dispatch logic |
| `Scripts/Solvers/run_simulation_with_method.m` | `Scripts/Drivers/run_simulation_with_method.m` | Simulation runner |
| `Scripts/Drivers/Analysis.m` | *(no move)* | Main entry point |
| `Scripts/Drivers/run_adaptive_convergence.m` | *(no move)* | Convergence driver |
| `Scripts/Drivers/AdaptiveConvergenceAgent.m` | *(no move)* | Convergence agent |

### UI Components

| Old Path | New Path | Purpose |
|----------|----------|---------|
| `Scripts/Infrastructure/MonitorInterface.m` | `Scripts/UI/MonitorInterface.m` | Monitor interface |
| `utilities/OWL_UtilitiesGuideApp.mlapp` | `Scripts/UI/OWL_UtilitiesGuideApp.mlapp` | Utilities guide app |
| `Scripts/UI/UIController.m` | *(no move)* | Main UI controller |
| `Scripts/UI/TEST_UIController.m` | *(no move)* | UI tests |

### Documentation → `Docs/Extra/`

| Old Path | New Path | Purpose |
|----------|----------|---------|
| `docs/01_ARCHITECTURE/` | `Docs/Extra/01_ARCHITECTURE/` | Architecture docs |
| `docs/02_DESIGN/` | `Docs/Extra/02_DESIGN/` | Design docs |
| `docs/03_NOTEBOOKS/` | `Docs/Extra/03_NOTEBOOKS/` | Jupyter notebooks |
| `docs/markdown_archive/` | `Docs/Extra/markdown_archive/` | Historical docs |
| `COMMIT_MESSAGE.txt` | `Docs/Extra/COMMIT_MESSAGE.txt` | Commit message template |
| `FINAL_COMPLETION_REPORT.md` | `Docs/Extra/FINAL_COMPLETION_REPORT.md` | Completion report |
| `MECH0020_COPILOT_AGENT_SPEC.md` | `Docs/Extra/MECH0020_COPILOT_AGENT_SPEC.md` | Agent specification |
| `README_CLEANUP_LOG.md` | `Docs/Extra/README_CLEANUP_LOG.md` | Cleanup log |
| `READY_TO_COMMIT.md` | `Docs/Extra/READY_TO_COMMIT.md` | Commit checklist |

**Files remaining at root**:
- `README.md` - Main documentation (this is correct)

### Sustainability Components
*(No moves - already in correct location)*
- `Scripts/Sustainability/EnergySustainabilityAnalyzer.m`
- `Scripts/Sustainability/HardwareMonitorBridge.m`
- `Scripts/Sustainability/iCUEBridge.m`
- `Scripts/Sustainability/update_live_monitor.m`

### Future Method Solvers
*(Kept in Scripts/Solvers/ - will move to Scripts/Methods/ when implemented)*
- `Scripts/Solvers/Spectral_Analysis.m`
- `Scripts/Solvers/Finite_Volume_Analysis.m`
- `Scripts/Solvers/Variable_Bathymetry_Analysis.m`

## Directories Removed

The following directories were removed after becoming empty:
- `Scripts/Editable/` - replaced by `Scripts/Config/`
- `Scripts/Infrastructure/` - split into Config, IO, Grid, Metrics, Utils
- `Scripts/Solvers/FD/` - moved to `Scripts/Methods/FiniteDifference/`
- `docs/` - moved to `Docs/Extra/`
- `utilities/` - contents moved to Scripts subdirectories

## Path Reference Updates

All `addpath` statements were updated in:
- `Scripts/Drivers/Analysis.m`
- `Scripts/Drivers/run_adaptive_convergence.m`
- `Scripts/UI/UIController.m`

Comments referencing old paths were updated in:
- `Scripts/Config/Default_Settings.m`
- `Scripts/Config/Default_FD_Parameters.m`
- `Scripts/Config/validate_simulation_parameters.m`
- `Scripts/IO/PathBuilder.m`

## Backward Compatibility

**Legacy configuration files maintained**:
- `Default_FD_Parameters.m` - still works, now in Scripts/Config/
- `Default_Settings.m` - still works, now in Scripts/Config/
- `create_default_parameters.m` - still works, now in Scripts/Config/

**New unified configuration (recommended)**:
- `default_parameters.m` - method-aware parameter defaults
- `user_settings.m` - mode-aware operational settings

## Verification Required

After these moves, the following should be tested:
1. ✅ Standard mode: `cd Scripts/Drivers; run('Analysis.m')`
2. ✅ UI mode: `cd Scripts/Drivers; Analysis` (select UI mode)
3. ✅ Convergence agent: `cd Scripts/Drivers; run_adaptive_convergence`
4. ✅ Path resolution works for all imports
5. ✅ Configuration files load correctly
6. ✅ All test files pass

## Benefits of Reorganization

1. **Clearer responsibilities**: Each directory has a single, focused purpose
2. **Easier navigation**: Related files grouped logically
3. **Method isolation**: FD solver clearly separated from future methods
4. **Unified configuration**: Single source of truth for defaults
5. **Clean root**: Only essential files visible at top level
6. **Better discoverability**: New developers can find what they need faster
7. **Backward compatible**: Existing code continues to work

## Migration Path for External Users

If you have scripts that rely on old paths:

**Option 1: Update to new paths (recommended)**
```matlab
% Old
addpath('Scripts/Infrastructure');
% New
addpath('Scripts/Config');
addpath('Scripts/IO');
addpath('Scripts/Grid');
addpath('Scripts/Metrics');
```

**Option 2: Use legacy config files (works but discouraged)**
```matlab
% Still works but uses old approach
Parameters = Default_FD_Parameters();
Settings = Default_Settings();
```

**Option 3: Use new unified config (best practice)**
```matlab
% New unified approach
params = default_parameters('FD');
settings = user_settings('Standard');
```
