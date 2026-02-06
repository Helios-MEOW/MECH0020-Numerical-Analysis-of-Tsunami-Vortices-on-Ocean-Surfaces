# Configuration Directory

This directory contains all user-editable configuration files for the MECH0020 Tsunami Vortex Simulation framework.

## Primary Configuration Files (USER-EDITABLE)

### `default_parameters.m`
**Single source of truth for simulation physics and numerics**

- Grid resolution (Nx, Ny, Lx, Ly)
- Physics parameters (viscosity, domain size)
- Time integration (dt, Tfinal, scheme)
- Initial conditions (IC type and coefficients)
- Output control (snapshots, monitoring)
- Method-specific parameters (FD, Spectral, FV, Bathymetry)

**Usage:**
```matlab
params = default_parameters();        % FD defaults
params = default_parameters('FD');    % Finite Difference
params = default_parameters('Spectral');  % Spectral method
params.Nx = 256;  % Override as needed
```

### `user_settings.m`
**Single source of truth for operational settings**

- IO settings (save figures, data, reports)
- Logging configuration (log level, verbosity)
- Plotting policy (format, DPI, renderer)
- Mode-specific settings (UI, Standard, Convergence)
- Monitor configuration (theme, refresh rate)
- Performance tuning (parallel execution)
- Debug options

**Usage:**
```matlab
settings = user_settings();           % Standard mode
settings = user_settings('UI');       % UI mode
settings = user_settings('Convergence');  % Convergence mode
settings.save_figures = false;  % Override as needed
```

## Legacy Configuration Files (MAINTAINED FOR COMPATIBILITY)

### `Default_FD_Parameters.m`
Original FD-specific parameter defaults. **Superseded by `default_parameters.m`.**
Kept for backward compatibility with existing scripts.

### `Default_Settings.m`
Original operational settings. **Superseded by `user_settings.m`.**
Kept for backward compatibility with existing scripts.

### `create_default_parameters.m`
Original comprehensive parameter factory. **Superseded by `default_parameters.m`.**
Kept for backward compatibility with legacy code.

## Supporting Configuration Files

### `Build_Run_Config.m`
Builds Run_Config struct (method, mode, IC) for dispatcher.

**Usage:**
```matlab
Run_Config = Build_Run_Config('FD', 'Evolution', 'Lamb-Oseen');
```

### `Build_Run_Status.m`
Builds Run_Status struct for tracking execution state.

### `validate_simulation_parameters.m`
Validates parameter structs before execution.

**Usage:**
```matlab
validate_simulation_parameters(params, settings);
```

## Configuration Workflow

### Standard Mode
```matlab
% 1. Load defaults
params = default_parameters('FD');
settings = user_settings('Standard');

% 2. Override as needed
params.Nx = 256;
params.Tfinal = 2.0;
settings.save_figures = false;

% 3. Validate
validate_simulation_parameters(params, settings);

% 4. Build run config
Run_Config = Build_Run_Config('FD', 'Evolution', 'Lamb-Oseen');

% 5. Execute
ModeDispatcher(Run_Config, params, settings);
```

### UI Mode
UI mode automatically loads `user_settings('UI')` and allows interactive parameter editing.

### Convergence Mode
Convergence studies should use `user_settings('Convergence')` for optimal data collection.

## Migration Guide

If you have existing code using the old configuration approach:

**Old way:**
```matlab
Parameters = Default_FD_Parameters();
Settings = Default_Settings();
```

**New way (recommended):**
```matlab
params = default_parameters('FD');
settings = user_settings('Standard');
```

**Both ways work** - the old files are maintained for compatibility.

## Customization Tips

1. **Edit once, use everywhere**: Modify defaults in `default_parameters.m` and `user_settings.m` rather than scattering overrides across scripts.

2. **Method-specific defaults**: Add new methods to the switch block in `default_parameters.m`.

3. **Mode-specific settings**: Add new execution modes to the switch block in `user_settings.m`.

4. **Document your changes**: Each parameter has inline comments explaining valid ranges and typical values.

5. **Validate early**: Call `validate_simulation_parameters()` before running to catch configuration errors.

## See Also

- `Scripts/Drivers/Analysis.m` - Main entry point showing configuration usage
- `Scripts/Drivers/run_adaptive_convergence.m` - Example of configuration in convergence studies
- `Docs/Extra/01_ARCHITECTURE/` - Architecture documentation
