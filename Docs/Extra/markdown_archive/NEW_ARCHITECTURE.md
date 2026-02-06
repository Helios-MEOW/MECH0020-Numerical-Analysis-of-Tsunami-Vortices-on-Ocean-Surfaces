# MECH0020 New Architecture - Quick Start

This document describes the new MECH0020-compliant architecture implemented according to the specification.

## Key Changes

### 1. Single UI: 3 Tabs (instead of 9)
- **Tab 1**: Setup/Configuration (method, mode, IC, parameters)
- **Tab 2**: Live Execution (monitor + convergence + metrics + terminal)
- **Tab 3**: Results (browse, query, recreate-from-PNG)

### 2. FD Modes: Fixed Set
- `Evolution` - Time evolution simulations
- `Convergence` - Grid convergence studies
- `ParameterSweep` - Parameter variation studies
- `Plotting` - Standalone visualization/recreate from data

Animation is a **setting**, not a mode.

### 3. Directory Structure (FD-compliant)
```
Results/
├── FD/
│   ├── Evolution/<run_id>/
│   │   ├── Figures/{Evolution,Contours,Vector,Streamlines,Animation}
│   │   ├── Reports/
│   │   └── Data/
│   ├── Convergence/<study_id>/
│   │   ├── Evolution/
│   │   ├── MeshContours/
│   │   ├── MeshGrids/
│   │   ├── MeshPlots/
│   │   ├── ConvergenceMetrics/
│   │   └── Reports/
│   ├── ParameterSweep/<study_id>/
│   │   ├── <param_name>/Figures/
│   │   ├── Reports/
│   │   └── Data/
│   └── Plotting/
│       └── (figure type directories)
└── Runs_Table.csv  (master table, all methods/modes)
```

### 4. User-Editable Defaults
All defaults are in `Scripts/Editable/`:
- `Default_FD_Parameters.m` - Physics + numerics
- `Default_Settings.m` - IO, logging, monitoring

### 5. Run ID System
Format: `<timestamp>_<method>_<mode>_<IC>_<grid>_<dt>_<hash>`
Example: `20260206T153042Z_FD_Evolution_LambOseen_g128_dt1e-3_hA1B2`

Figure names: `<run_id>__<figure_type>__<variant>.png`

### 6. Professional Reports
Each run generates `Report.txt` with:
- System metadata (MATLAB version, OS, git commit)
- Configuration and parameters
- Results summary
- File manifest

### 7. Master Runs Table
`Results/Runs_Table.csv` tracks all runs across methods/modes.
Append-safe with schema evolution.
Optional Excel export with conditional formatting.

## Quick Start

### Standard Mode (Command Line)
```matlab
cd Scripts/Main
Analysis_New  % New thin driver
```

Edit configuration in `Analysis_New.m`:
```matlab
Run_Config = Build_Run_Config('FD', 'Evolution', 'Lamb-Oseen');
Parameters = Default_FD_Parameters();
Parameters.Nx = 256;  % Override defaults
Settings = Default_Settings();
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

### UI Mode (3 Tabs)
```matlab
cd Scripts/Main
Analysis_New  % Set run_type = 'ui'
```

### Testing
```matlab
cd tests
Run_All_Tests  % Master test runner
```

## Architecture Components

### Infrastructure (`Scripts/Infrastructure/`)
- `PathBuilder` - Directory structure creation
- `RunIDGenerator` - Run ID generation and parsing
- `ModeDispatcher` - Route to appropriate mode module
- `MonitorInterface` - Live monitoring (start/update/stop)
- `RunReportGenerator` - Professional reports
- `MasterRunsTable` - CSV master table
- `Build_Run_Config` - Configuration builder
- `Build_Run_Status` - Status builder for monitors

### Mode Modules (`Scripts/Methods/`)
- `FD_Evolution_Mode.m`
- `FD_Convergence_Mode.m`
- `FD_ParameterSweep_Mode.m`
- `FD_Plotting_Mode.m`

### Editable Defaults (`Scripts/Editable/`)
- `Default_FD_Parameters.m`
- `Default_Settings.m`

### Testing (`tests/`)
- `Run_All_Tests.m` - Master test runner
- `Test_Cases.m` - Minimal test configurations

## Migration Path

### Phase 1: New infrastructure available (CURRENT)
- New modules exist alongside old Analysis.m
- Use `Analysis_New.m` to try new architecture
- Old `Analysis.m` still works for compatibility

### Phase 2: UI refactor (NEXT)
- Update `UIController.m` from 9 tabs to 3 tabs
- Integrate with new mode modules

### Phase 3: Deprecate old Analysis.m
- Move old Analysis.m to `Analysis_Legacy.m`
- Rename `Analysis_New.m` to `Analysis.m`

## Example Workflows

### Evolution Run
```matlab
Run_Config = Build_Run_Config('FD', 'Evolution', 'Lamb-Oseen');
Parameters = Default_FD_Parameters();
Settings = Default_Settings();
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

### Convergence Study
```matlab
Run_Config = Build_Run_Config('FD', 'Convergence', 'Gaussian');
Parameters = Default_FD_Parameters();
Parameters.mesh_sizes = [32, 64, 128, 256];
Parameters.convergence_variable = 'max_omega';
Settings = Default_Settings();
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

### Parameter Sweep
```matlab
Run_Config = Build_Run_Config('FD', 'ParameterSweep', 'Lamb-Oseen');
Parameters = Default_FD_Parameters();
Parameters.sweep_parameter = 'nu';
Parameters.sweep_values = [0.001, 0.002, 0.004];
Settings = Default_Settings();
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

### Recreate from PNG
```matlab
% Find run_id from PNG filename
run_id = RunIDGenerator.extract_from_filename('my_figure.png');

% Create plotting run
Run_Config = Build_Run_Config('FD', 'Plotting', 'Lamb-Oseen', 'source_run_id', run_id);
Parameters.plot_types = {'contours', 'streamlines'};
[Results, paths] = ModeDispatcher(Run_Config, Parameters, Settings);
```

## Testing

Run all tests:
```matlab
cd tests
Run_All_Tests
```

Individual test:
```matlab
cases = Get_Test_Cases();
[Results, paths] = ModeDispatcher(cases(1).Run_Config, cases(1).Parameters, cases(1).Settings);
```

## Documentation Placeholders

Following MECH0020 spec, no fabricated citations or ASCII diagrams.

Where references needed: `[[REF NEEDED: description]]`
Where figures needed: `[[FIGURE PLACEHOLDER: description]]`
