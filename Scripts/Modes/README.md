# Modes Directory

**Purpose:** Contains method-agnostic mode scripts that orchestrate simulations.

## Architecture Rule

**CRITICAL:** There must be EXACTLY ONE script per mode. NO mode-per-method files.

❌ **WRONG:**
- `FD_Evolution_Mode.m`
- `Spectral_Evolution_Mode.m`
- `FV_Evolution_Mode.m`

✅ **CORRECT:**
- `mode_evolution.m` (handles ALL methods internally)

## How Modes Work

Each mode script:

1. **Validates** mode-specific configuration
2. **Resolves method** via internal `resolve_method()` function (switch/case)
3. **Runs orchestration loop** ONCE (shared across all methods)
4. **Calls method callbacks:** `init_fn(cfg, ctx)`, `step_fn(State, cfg, ctx)`, `diag_fn(State, cfg, ctx)`
5. **Produces outputs** using single saving/plotting etiquette for that mode

## Method Dispatch Pattern

Every mode script MUST include this pattern:

```matlab
function [init_fn, step_fn, diag_fn] = resolve_method(method_name)
    switch lower(method_name)
        case 'fd'
            init_fn = @fd_init;
            step_fn = @fd_step;
            diag_fn = @fd_diagnostics;
        case {'spectral', 'fft'}
            init_fn = @spectral_init;
            step_fn = @spectral_step;
            diag_fn = @spectral_diagnostics;
        case {'fv', 'finitevolume'}
            init_fn = @fv_init;
            step_fn = @fv_step;
            diag_fn = @fv_diagnostics;
        otherwise
            error('Unknown method: %s', method_name);
    end
end
```

This is the ONLY place where method branching occurs. The orchestration loop is identical for all methods.

## Available Modes

### Evolution Mode (`mode_evolution.m`)
- **Purpose:** Time evolution simulation
- **Outputs:** Snapshots at specified times, time history of diagnostics, figures
- **Required Parameters:** `Tfinal`, `dt`, `snap_times`

### Convergence Mode (`Convergence/mode_convergence.m`)
- **Purpose:** Grid refinement convergence study
- **Outputs:** QoI vs mesh size, convergence order, convergence plots
- **Required Parameters:** `mesh_sizes` (array of grid resolutions)

### Parameter Sweep Mode (`mode_parameter_sweep.m`)
- **Purpose:** Parameter sensitivity study
- **Outputs:** QoI vs parameter value, sweep plots
- **Required Parameters:** `sweep_parameter` (name), `sweep_values` (array)

### Plotting Mode (`mode_plotting.m`)
- **Purpose:** Visualize existing simulation results
- **Outputs:** Contours, streamlines, time evolution plots
- **Required Parameters:** `source_run_id` (ID of run to plot)
- **Note:** Method-agnostic - works with data from any method

## Compatibility Enforcement

Each mode script SHOULD check compatibility early:

```matlab
[ok, issues] = validate_<mode>(Run_Config, Parameters);
if ~ok
    error('Mode validation failed: %s', strjoin(issues, '; '));
end
```

Use `compatibility_matrix(method, mode)` from `Scripts/Infrastructure/Compatibility/` to block invalid combinations.

## What Each Mode Owns

Modes are responsible for:

- ✅ Orchestration loop logic (time integration, convergence iteration, parameter sweep iteration)
- ✅ Output folder / run ID / manifest logic
- ✅ Snapshot timing and storage
- ✅ Logging and progress reporting
- ✅ Figure/animation export etiquette
- ✅ Validation for mode-specific parameters

Methods provide ONLY:
- Init/step/diagnostics kernels
- Method-specific operators (Arakawa Jacobian, FFT Poisson solver, etc.)

## Adding a New Mode

1. Create `mode_<name>.m` in this directory
2. Follow the template from `mode_evolution.m`
3. Include internal `resolve_method()` function
4. Add mode to `Tsunami_Simulator.m` dispatch switch
5. Add compatibility rules in `compatibility_matrix.m`
6. DO NOT create mode-per-method files (e.g., `FD_<name>.m`)
