# Quick Reference - Tsunami Vorticity Emulator

## Running Simulations

```matlab
% Interactive (choose UI or Standard)
Tsunami_Vorticity_Emulator()

% Direct UI mode
Tsunami_Vorticity_Emulator('Mode', 'UI')

% Direct Standard mode (batch-friendly)
Tsunami_Vorticity_Emulator('Mode', 'Standard', ...
    'Method', 'FD', 'SimMode', 'Evolution', ...
    'IC', 'Lamb-Oseen', 'Nx', 256, 'Tfinal', 1.0)
```

## 9 Initial Condition Types

| IC Type | Description | Coefficients |
|---------|-------------|--------------|
| `'Lamb-Oseen'` | Classic viscous vortex | `[Gamma, a]` |
| `'Rankine'` | Piecewise constant vortex | `[Gamma, a]` |
| `'Lamb-Dipole'` | Counter-rotating pair | `[Gamma, a, separation]` |
| `'Taylor-Green'` | Periodic cellular flow | `[k_x, k_y]` |
| `'Stretched-Gaussian'` | Anisotropic Gaussian | `[x_coeff, y_coeff, angle, x0, y0]` |
| `'Elliptical-Vortex'` | Elliptical core | `[a, b, angle]` |
| `'Random-Turbulence'` | Multi-scale turbulence | `[k_max, seed]` |
| `'Gaussian'` | Simple Gaussian | `[amplitude, width]` |
| `'Custom'` | User-defined | User-specified |

## Key Parameters (Parameters.m)

```matlab
% Physics
params.nu = 0.001;              % Viscosity
params.Lx = 2*pi;               % Domain X
params.Ly = 2*pi;               % Domain Y

% Grid
params.Nx = 128;                % Grid points X
params.Ny = 128;                % Grid points Y

% Time
params.dt = 0.001;              % Timestep
params.Tfinal = 1.0;            % Final time

% Initial Condition
params.ic_type = 'Lamb-Oseen';  % IC type
params.ic_coeff = [];           % Use defaults

% Snapshots (SEPARATE CONTROLS!)
params.num_plot_snapshots = 11;    % Plot snapshots
params.animation_num_frames = 100; % Animation frames
```

## Key Settings (Settings.m)

```matlab
% Output
s.save_figures = true;
s.save_data = true;
s.figure_format = 'png';        % png, pdf, eps
s.figure_dpi = 300;

% Animation (INDEPENDENT from plots!)
s.animation_enabled = false;
s.animation_format = 'gif';     % gif, mp4, avi
s.animation_fps = 30;

% Monitor
s.monitor_enabled = true;
s.monitor_theme = 'dark';       % dark, light
```

## Methods

- **FD**: Finite Difference (✅ Fully Implemented)
- **Spectral**: FFT-based (🔧 Framework Ready)
- **FV**: Finite Volume (🔧 Framework Ready)

## Modes

- **Evolution**: Time evolution simulation
- **Convergence**: Grid refinement study
- **ParameterSweep**: Parameter sensitivity
- **Plotting**: Visualize existing results

## NEW: Plot vs Animation Control

**Problem**: Want detailed snapshots but smooth animations

**Solution**:
```matlab
% Parameters.m
params.num_plot_snapshots = 11;      % 11 static plots
params.animation_num_frames = 200;   % 200 animation frames

% Settings.m
s.save_figures = true;               % Enable plot saving
s.animation_enabled = true;          % Enable animation
```

**Result**: 11 plots + 200-frame animation independently!

## Configuration Files

| File | Location | Purpose |
|------|----------|---------|
| `Tsunami_Vorticity_Emulator.m` | `Scripts/Drivers/` | Main entry point |
| `Parameters.m` | `Scripts/Editable/` | Physics & numerics |
| `Settings.m` | `Scripts/Editable/` | Operational settings |

## Common Tasks

### Change IC Type
```matlab
% Edit Parameters.m
params.ic_type = 'Rankine';
params.ic_coeff = [1.5, 0.4];
```

### Increase Resolution
```matlab
% Edit Parameters.m
params.Nx = 256;
params.Ny = 256;
params.dt = 0.0005;  % Reduce dt for stability
```

### Generate High-Quality Animations
```matlab
% Edit Parameters.m
params.animation_num_frames = 300;

% Edit Settings.m
s.animation_enabled = true;
s.animation_format = 'mp4';
s.animation_fps = 60;
s.animation_quality = 95;
```

### Batch Automation
```matlab
% No edits needed - use command line
Tsunami_Vorticity_Emulator('Mode', 'Standard', ...
    'Method', 'FD', 'IC', 'Taylor-Green', ...
    'Nx', 128, 'Tfinal', 2.0, ...
    'SaveFigs', 1, 'Monitor', 0)
```

## File Locations

```
Scripts/
├── Drivers/
│   └── Tsunami_Vorticity_Emulator.m    ← RUN THIS
├── Editable/
│   ├── Parameters.m                     ← EDIT: Physics
│   └── Settings.m                       ← EDIT: I/O
└── Infrastructure/
    └── Initialisers/
        └── ic_factory.m                 ← IC implementations
```

## Documentation

- **Full Guide**: `docs/TSUNAMI_VORTICITY_EMULATOR_GUIDE.md`
- **Inline Docs**: All parameters documented in `Parameters.m` and `Settings.m`
- **IC Details**: See `Scripts/Infrastructure/Initialisers/ic_factory.m`

---

**Quick Start**: Edit `Parameters.m`, run `Tsunami_Vorticity_Emulator()`
