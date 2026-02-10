# Tsunami Vorticity Emulator - User Guide

**Version 2.0** - Enhanced Parameter Control Framework

---

## Overview

The **Tsunami Vorticity Emulator** is a unified driver file that provides a single entry point for all tsunami vortex simulations. It combines and supersedes the previous driver files (Analysis.m, Tsunami_Simulator.m, MECH0020_Run.m).

### Key Features

- **Single Entry Point**: One driver file for all simulation modes
- **Comprehensive Configuration**: Detailed parameter and settings files
- **9 Initial Conditions**: Full catalog of vortex types
- **Multiple Methods**: Finite Difference (FD), Spectral, Finite Volume (FV)
- **Flexible Modes**: Evolution, Convergence, Parameter Sweep, Plotting
- **Batch-Friendly**: Command-line arguments for automated runs
- **UI Support**: Integrated 3-tab graphical interface

---

## Quick Start

### Interactive Mode (Default)

```matlab
Tsunami_Vorticity_Emulator()
```

This launches a startup dialog where you can choose:
- **UI Mode**: 3-tab graphical interface
- **Standard Mode**: Command-line with dispatcher

### Direct Standard Mode

```matlab
Tsunami_Vorticity_Emulator('Mode', 'Standard')
```

Runs with default parameters from `Parameters.m` and `Settings.m`.

### Batch Mode (Fully Automated)

```matlab
Tsunami_Vorticity_Emulator('Mode', 'Standard', ...
    'Method', 'FD', ...
    'SimMode', 'Evolution', ...
    'IC', 'Lamb-Oseen', ...
    'Nx', 256, 'Ny', 256, ...
    'dt', 0.0005, 'Tfinal', 2.0)
```

---

## Configuration Files

### Parameters.m (Physics & Numerics)

**Location**: `Scripts/Editable/Parameters.m`

**Purpose**: Controls all physics, numerics, and initial conditions

#### Key Sections

1. **Physics Parameters**
   - `nu`: Kinematic viscosity
   - `Lx`, `Ly`: Domain size
   - `bathymetry_*`: Ocean floor depth (future feature)

2. **Grid Parameters**
   - `Nx`, `Ny`: Grid resolution
   - Method-specific settings for FD, Spectral, FV

3. **Time Integration**
   - `dt`: Timestep
   - `Tfinal`: Final simulation time
   - `time_scheme`: Integration method (RK4, RK3, AB3, Euler)

4. **Initial Conditions**
   - `ic_type`: IC type (see catalog below)
   - `ic_coeff`: Coefficients for selected IC

5. **Output Control** ⭐ NEW
   - `num_plot_snapshots`: Number of saved figure snapshots
   - `animation_num_frames`: Number of animation frames
   - **Separate control for plots vs animations!**

#### Example Customization

```matlab
% Edit Parameters.m:

% Physics
params.nu = 0.002;           % Higher viscosity

% Grid
params.Nx = 256;             % Higher resolution
params.Ny = 256;

% Time
params.dt = 0.0005;          % Smaller timestep
params.Tfinal = 2.0;         % Longer simulation

% Initial Condition
params.ic_type = 'Rankine';  % Different vortex type
params.ic_coeff = [1.5, 0.3]; % Custom coefficients

% Snapshots
params.num_plot_snapshots = 21;     % 21 figure snapshots
params.animation_num_frames = 200;   % 200 animation frames
```

---

### Settings.m (Operational Controls)

**Location**: `Scripts/Editable/Settings.m`

**Purpose**: Controls I/O, plotting, monitoring, and method-specific options

#### Key Sections

1. **I/O Settings**
   - `save_figures`, `save_data`, `save_animations`
   - `figure_format`: png, pdf, eps, svg
   - `data_format`: mat, hdf5

2. **Figure Settings**
   - `figure_dpi`: Resolution (300 default)
   - `colormap`: turbo, viridis, parula, jet
   - `plot_contours`, `plot_quiver`, etc.

3. **Animation Settings** ⭐ NEW
   - `animation_enabled`: Turn on/off
   - `animation_format`: gif, mp4, avi
   - `animation_fps`: Frame rate
   - **Independent from plot snapshots!**

4. **Monitor/UI**
   - `monitor_enabled`: Live progress monitor
   - `monitor_theme`: dark, light

5. **Method-Specific Settings** ⭐ NEW
   - `fd_matrix_free`: Finite Difference optimization
   - `spectral_fft_plan`: Spectral method FFT planning
   - `fv_flux_cache`: Finite Volume flux caching

#### Example Customization

```matlab
% Edit Settings.m:

% Save high-quality PDFs
s.save_figures = true;
s.figure_format = 'pdf';
s.figure_dpi = 600;

% Generate smooth animations
s.animation_enabled = true;
s.animation_format = 'mp4';
s.animation_fps = 60;
s.animation_quality = 95;

% Disable live monitor for batch runs
s.monitor_enabled = false;
```

---

## Initial Conditions Catalog

**9 IC Types Available** - All documented in `Parameters.m`

### 1. Lamb-Oseen Vortex
**Code**: `'Lamb-Oseen'`  
**Description**: Classic viscous vortex (axisymmetric)  
**Coefficients**: `[Gamma, a]`
- `Gamma`: Circulation strength (default: 1.0)
- `a`: Core radius (default: 0.5)

**Formula**: `omega = (Gamma/(2*pi*a^2)) * exp(-r^2/(2*a^2))`

**Example**:
```matlab
params.ic_type = 'Lamb-Oseen';
params.ic_coeff = [2.0, 0.3];  % Strong, compact vortex
```

---

### 2. Rankine Vortex
**Code**: `'Rankine'`  
**Description**: Piecewise constant vortex (solid body core + potential flow)  
**Coefficients**: `[Gamma, a]`
- `Gamma`: Circulation (default: 1.0)
- `a`: Core radius (default: 0.5)

**Formula**: `omega = 2*Gamma/(pi*a^2)` for `r <= a`, `0` otherwise

**Example**:
```matlab
params.ic_type = 'Rankine';
params.ic_coeff = [1.5, 0.4];  % Medium strength, moderate core
```

---

### 3. Lamb Dipole
**Code**: `'Lamb-Dipole'`  
**Description**: Counter-rotating vortex pair  
**Coefficients**: `[Gamma, a, separation]`
- `Gamma`: Circulation (default: 1.0)
- `a`: Core radius (default: 0.5)
- `separation`: Distance between vortices (default: 2*a)

**Example**:
```matlab
params.ic_type = 'Lamb-Dipole';
params.ic_coeff = [1.0, 0.5, 1.5];  % Standard dipole
```

---

### 4. Taylor-Green Vortex
**Code**: `'Taylor-Green'`  
**Description**: Periodic cellular flow pattern  
**Coefficients**: `[k_x, k_y]`
- `k_x`: Wavenumber in x (default: 1)
- `k_y`: Wavenumber in y (default: 1)

**Formula**: `omega = sin(k_x*2*pi*x) * sin(k_y*2*pi*y)`

**Example**:
```matlab
params.ic_type = 'Taylor-Green';
params.ic_coeff = [2, 2];  % Finer cellular pattern
```

---

### 5. Stretched Gaussian
**Code**: `'Stretched-Gaussian'`  
**Description**: Anisotropic Gaussian vortex  
**Coefficients**: `[x_coeff, y_coeff, angle, x0, y0]`
- `x_coeff`: X-direction width (default: 2.0)
- `y_coeff`: Y-direction width (default: 0.2)
- `angle`: Rotation angle in degrees (default: 0)
- `x0`, `y0`: Center position (default: 0, 0)

**Example**:
```matlab
params.ic_type = 'Stretched-Gaussian';
params.ic_coeff = [3.0, 0.5, 45, 0, 0];  % Elongated, rotated
```

---

### 6. Elliptical Vortex
**Code**: `'Elliptical-Vortex'`  
**Description**: Elliptical vortex core  
**Coefficients**: `[a, b, angle]`
- `a`: Semi-major axis (default: 1.5)
- `b`: Semi-minor axis (default: 1.0)
- `angle`: Rotation angle in degrees (default: 0)

**Example**:
```matlab
params.ic_type = 'Elliptical-Vortex';
params.ic_coeff = [2.0, 0.8, 30];  % Elliptical, tilted
```

---

### 7. Random Turbulence
**Code**: `'Random-Turbulence'`  
**Description**: Multi-scale turbulent field  
**Coefficients**: `[k_max, seed]`
- `k_max`: Maximum wavenumber (default: 4)
- `seed`: Random seed (default: 42)

**Example**:
```matlab
params.ic_type = 'Random-Turbulence';
params.ic_coeff = [8, 123];  % Finer scales, different realization
```

---

### 8. Gaussian Vortex
**Code**: `'Gaussian'`  
**Description**: Simple isotropic Gaussian vortex  
**Coefficients**: `[amplitude, width]`
- `amplitude`: Peak vorticity (default: 1.0)
- `width`: Characteristic width (default: 1.0)

**Example**:
```matlab
params.ic_type = 'Gaussian';
params.ic_coeff = [2.5, 0.6];  % Strong, compact
```

---

### 9. Custom IC
**Code**: `'Custom'`  
**Description**: User-defined IC  
**Implementation**: Edit `ic_factory.m` to add custom case

---

## Numerical Methods

### Finite Difference (FD)
**Status**: ✅ Fully Implemented  
**Code**: `'FD'`

**Settings in Parameters.m**:
```matlab
params.fd_boundary_type = 'periodic';  % Boundary conditions
params.fd_stencil = 'central';         % Stencil type
params.fd_order = 2;                   % Accuracy order
```

**Settings in Settings.m**:
```matlab
s.fd_matrix_free = true;        % Matrix-free operators
s.fd_parallel = false;          % Parallel computing
```

---

### Spectral Method
**Status**: 🔧 Framework Ready (Implementation Pending)  
**Code**: `'Spectral'`

**Settings in Parameters.m**:
```matlab
params.spectral_dealias = true;         % Anti-aliasing
params.spectral_filter = 'exponential'; % Filtering
params.spectral_padding = 1.5;          % Dealiasing padding
```

**Settings in Settings.m**:
```matlab
s.spectral_fft_plan = 'fftw';      % FFT planning
s.spectral_save_modes = false;     % Save Fourier modes
```

---

### Finite Volume (FV)
**Status**: 🔧 Framework Ready (Implementation Pending)  
**Code**: `'FV'`

**Settings in Parameters.m**:
```matlab
params.fv_flux_scheme = 'MUSCL';   % Flux scheme
params.fv_limiter = 'vanLeer';     % Slope limiter
params.fv_reconstruction_order = 2; % Reconstruction order
```

**Settings in Settings.m**:
```matlab
s.fv_flux_cache = true;            % Cache flux computations
s.fv_adaptive_limiter = false;     % Adaptive limiting
```

---

## Simulation Modes

### Evolution Mode
**Purpose**: Time evolution of vorticity field

**Example**:
```matlab
Tsunami_Vorticity_Emulator('Mode', 'Standard', ...
    'Method', 'FD', ...
    'SimMode', 'Evolution', ...
    'IC', 'Lamb-Oseen')
```

---

### Convergence Mode
**Purpose**: Grid refinement study

**Settings in Parameters.m**:
```matlab
params.convergence_mesh_sizes = [32, 64, 128, 256];
params.convergence_norms = {'L2', 'Linf'};
```

---

### Parameter Sweep Mode
**Purpose**: Parameter sensitivity study

**Settings in Parameters.m**:
```matlab
params.sweep_parameter = 'nu';
params.sweep_values = [0.0005, 0.001, 0.002];
```

---

### Plotting Mode
**Purpose**: Regenerate plots from saved data

**Settings in Settings.m**:
```matlab
s.plotting_regenerate = true;
s.plotting_custom_times = [0, 0.5, 1.0];
```

---

## Advanced Features

### Separate Plot and Animation Control ⭐ NEW

**Problem Solved**: Users want detailed snapshot plots but smooth animations

**Solution**: Independent control in `Parameters.m`

```matlab
% In Parameters.m:

% Plot Snapshots (for analysis)
params.num_plot_snapshots = 11;      % 11 detailed snapshots
params.snap_times = linspace(0, params.Tfinal, 11);

% Animation Frames (for visualization)
params.animation_enabled = true;
params.animation_num_frames = 200;   % 200 smooth frames
```

**Result**: 
- 11 high-quality PNG/PDF snapshots saved for analysis
- 200-frame smooth GIF/MP4 animation for presentation

---

### Future Features Framework ⭐ NEW

Settings prepared for easy integration:

#### Adaptive Mesh Refinement (AMR)
```matlab
s.amr_enabled = false;              % Ready to enable
s.amr_max_level = 3;
```

#### GPU Acceleration
```matlab
s.use_gpu = false;                  % Ready to enable
```

#### Machine Learning
```matlab
s.ml_acceleration = false;          % Framework ready
s.ml_model_path = '';
```

#### Multi-Physics
```matlab
s.coupled_temperature = false;      % Framework ready
s.coupled_salinity = false;
```

---

## Migration Guide

### From Analysis.m

**Old Way**:
```matlab
% Edit Analysis.m directly (lines 88-106)
Parameters.Nx = 128;
% Run Analysis.m
```

**New Way**:
```matlab
% Edit Parameters.m (dedicated file)
params.Nx = 128;
% Run Tsunami_Vorticity_Emulator()
```

---

### From Tsunami_Simulator.m

**Old Way**:
```matlab
Tsunami_Simulator()  % Interactive prompts
```

**New Way**:
```matlab
Tsunami_Vorticity_Emulator()  % Same interactive mode
% OR batch mode for automation
```

---

### From MECH0020_Run.m

**Old Way**:
```matlab
MECH0020_Run('Mode', 'Standard', ...)
```

**New Way**:
```matlab
Tsunami_Vorticity_Emulator('Mode', 'Standard', ...)
% Same interface, enhanced documentation
```

---

## Best Practices

### 1. Start Simple
```matlab
% First run: Use defaults
Tsunami_Vorticity_Emulator()
% Select UI or Standard mode from dialog
```

### 2. Customize Parameters
```matlab
% Edit Parameters.m for your physics
params.ic_type = 'Rankine';
params.Nx = 256;
params.Tfinal = 2.0;
```

### 3. Customize Settings
```matlab
% Edit Settings.m for output preferences
s.figure_format = 'pdf';
s.animation_enabled = true;
```

### 4. Run Batch Jobs
```matlab
% Use command-line mode for automation
Tsunami_Vorticity_Emulator('Mode', 'Standard', ...
    'Method', 'FD', 'IC', 'Lamb-Oseen', ...
    'Nx', 256, 'Tfinal', 1.0)
```

---

## Troubleshooting

### Issue: "Unknown IC type"
**Solution**: Check `ic_type` spelling in Parameters.m. Use exact names from catalog (case-insensitive).

### Issue: "Simulation unstable"
**Solution**: Reduce `dt` or increase `Nx`, `Ny`. Check CFL number in configuration report.

### Issue: "Animation not generated"
**Solution**: Enable in both places:
```matlab
% Parameters.m
params.animation_enabled = true;

% Settings.m
s.animation_enabled = true;
```

### Issue: "Plots but no animations" or vice versa
**Solution**: These are independent! Check both:
- `params.num_plot_snapshots` for static plots
- `params.animation_num_frames` for animations
- `s.save_figures` and `s.animation_enabled` in Settings.m

---

## Summary of Key Improvements

✅ **Single Unified Driver**: One entry point instead of three  
✅ **9 Documented ICs**: Full catalog with examples  
✅ **Method Framework**: FD, Spectral, FV all configured  
✅ **Independent Plot/Animation Control**: Different temporal resolutions  
✅ **Future-Ready**: AMR, GPU, ML frameworks prepared  
✅ **Comprehensive Documentation**: Every parameter explained inline  
✅ **Batch-Friendly**: Command-line automation support  

---

## Contact & Support

For issues or questions:
1. Check this guide
2. Review inline comments in Parameters.m and Settings.m
3. See `ic_factory.m` for IC implementation details
4. Consult framework documentation in Scripts/Infrastructure/

---

**Version**: 2.0  
**Last Updated**: February 2026  
**Author**: MECH0020 Analysis Framework
