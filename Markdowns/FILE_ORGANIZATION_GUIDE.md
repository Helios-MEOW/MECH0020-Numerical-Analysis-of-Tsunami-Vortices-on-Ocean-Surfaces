# File Organization Guide

## Overview
This document describes the new file organization system for Analysis.m outputs, which has been improved to make results easily discoverable and differentiate between the three operational modes (EVOLUTION, CONVERGENCE, SWEEP).

## New Directory Structure

### Evolution Mode
```
Figures/
├── Finite Difference/
│   └── EVOLUTION/
│       ├── Evolution/
│       │   └── EVOLUTION_20260127_143522_Nx=128_Ny=128_nu=1e-06_dt=0.01_Tfinal=1.0_ic=stretched_gaussian_coeff[1.00,2.00]_Evolution.png
│       ├── Contour/
│       │   └── EVOLUTION_20260127_143522_Nx=128_Ny=128_nu=1e-06_dt=0.01_Tfinal=1.0_ic=stretched_gaussian_coeff[1.00,2.00]_Contour.png
│       └── Vectorised/
│           └── EVOLUTION_20260127_143522_Nx=128_Ny=128_nu=1e-06_dt=0.01_Tfinal=1.0_ic=stretched_gaussian_coeff[1.00,2.00]_Vectorised.png
```

### Convergence Mode
```
Figures/
├── Finite Difference/
│   └── CONVERGENCE/
│       └── Convergence/
│           ├── Phase_Coarse/
│           │   └── 20260127_143522_N0320_Nx=256_Ny=256/
│           │       ├── conv_coarse_iter0001_N0320_Evolution.png
│           │       ├── conv_coarse_iter0001_N0320_Contour.png
│           │       └── conv_coarse_iter0001_N0320_Vectorised.png
│           ├── Phase_Bracketing/
│           │   └── 20260127_143623_N0512_Nx=512_Ny=512/
│           │       └── ...
│           ├── Phase_BinarySearch/
│           │   └── 20260127_143723_N0512_Nx=512_Ny=512/
│           │       └── ...
│           └── Phase_FinalValidation/
│               └── ...
│
└── Animations/
    └── CONVERGENCE/
        └── converged_mesh_20260127_143822_Nx=1024_Ny=1024.mp4
```

### Sweep Mode
```
Figures/
├── Finite Difference/
│   └── SWEEP/
│       ├── Evolution/
│       │   ├── SWEEP_20260127_150000_Nx=256_Ny=256_nu=1e-07_dt=0.01_Tfinal=1.0_ic=stretched_gaussian_coeff[1.00,2.00]_Evolution.png
│       │   ├── SWEEP_20260127_150001_Nx=256_Ny=256_nu=1e-06_dt=0.01_Tfinal=1.0_ic=stretched_gaussian_coeff[1.00,2.00]_Evolution.png
│       │   ├── SWEEP_20260127_150002_Nx=256_Ny=256_nu=1e-05_dt=0.01_Tfinal=1.0_ic=stretched_gaussian_coeff[1.00,2.00]_Evolution.png
│       │   └── ...
│       ├── Contour/
│       │   └── ...
│       └── Vectorised/
│           └── ...
```

## Filename Format

### Standard Case Figures
```
MODE_YYYYMMDD_HHMMSS_Nx=X_Ny=Y_nu=NUVAL_dt=DTVAL_Tfinal=TFVAL_ic=IC_TYPE[_coeff[X,Y]]_FIGTYPE.png
```

**Components:**
- `MODE`: EVOLUTION, CONVERGENCE, SWEEP, or ANIMATION
- `YYYYMMDD_HHMMSS`: Date and time in compact format (e.g., 20260127_143522)
- `Nx=X, Ny=Y`: Grid dimensions (e.g., Nx=256_Ny=256)
- `nu=NUVAL`: Viscosity coefficient in scientific notation (e.g., nu=1.00e-06)
- `dt=DTVAL`: Timestep in scientific notation (e.g., dt=1.00e-02)
- `Tfinal=TFVAL`: Final time in decimal format (e.g., Tfinal=1.0)
- `ic=IC_TYPE`: Initial condition type (e.g., ic=stretched_gaussian)
- `coeff[X,Y]`: Optional coefficients for parameterized ICs (e.g., coeff[1.00,2.00])
- `FIGTYPE`: Figure category (Evolution, Contour, Vectorised)

**Example:**
```
EVOLUTION_20260127_143522_Nx=128_Ny=128_nu=1.00e-06_dt=1.00e-02_Tfinal=1.0_ic=stretched_gaussian_coeff[1.00,2.00]_Evolution.png
```

### Convergence Iteration Figures
```
conv_PHASE_iter#### _N####_FIGTYPE.png
```

**Components:**
- `conv_`: Prefix indicating convergence iteration
- `PHASE`: coarse, bracketing, binarysearch, or finalvalidation
- `iter####`: 4-digit iteration counter (e.g., iter0001)
- `N####`: 4-digit grid resolution (e.g., N0320)
- `FIGTYPE`: Figure category (Evolution, Contour, Vectorised)

**Example:**
```
conv_coarse_iter0005_N0512_Contour.png
```

## Benefits of This Organization

### 1. **Mode-Based Separation**
- All EVOLUTION figures are in `Figures/FD/EVOLUTION/`
- All CONVERGENCE figures are in `Figures/FD/CONVERGENCE/`
- All SWEEP figures are in `Figures/FD/SWEEP/`
- Easy to locate results by workflow type

### 2. **Timestamp Ordering**
- Filenames include `YYYYMMDD_HHMMSS` immediately after mode
- Files naturally sort chronologically when sorted alphabetically
- Easy to find most recent results

### 3. **Parameter Information**
- All relevant parameters (Nx, Ny, nu, dt, Tfinal, ic_type) in filename
- No need to check parameter files to understand result
- Parameter sweep results are easily differentiated

### 4. **Figure Type Subdirectories**
- Evolution, Contour, Vectorised figures separated by type
- Easy to locate specific visualization type
- Cleaner browsing experience

### 5. **Convergence Phase Tracking**
- Convergence study phases organized in subfolders
- Each phase clearly labeled (Coarse, Bracketing, BinarySearch, FinalValidation)
- Iteration figures grouped by grid resolution (N value)

## Migration from Old System

### Old Naming Format
```
YYYY-MM-DD_HH-MM-SS_nu=X_dt=Y_Tfinal=Z_ic=TYPE_figname.png
```

### Changes Made
1. **Mode prefix added**: All filenames now start with MODE (EVOLUTION, CONVERGENCE, SWEEP)
2. **Timestamp reformatted**: `YYYY-MM-DD_HH-MM-SS` → `YYYYMMDD_HHMMSS` (more compact, filesystem-friendly)
3. **Grid resolution added**: `Nx=X_Ny=Y` now included in all filenames
4. **Directory structure enhanced**: Mode-level subdirectory added (`Figures/FD/MODE/TYPE/`)

### Backward Compatibility
- Old figures (from before this update) will remain in their original locations
- New runs will use the improved naming and organization
- Both old and new results can coexist in the same `Figures/` directory

## How to Find Your Results

### Example 1: Finding Evolution Mode Results from Today
```powershell
# Navigate to evolution results
cd Figures/FD/EVOLUTION/

# Find all PNG files (sorted by mode and timestamp)
ls -R *.png
```

### Example 2: Finding Convergence Study Phases
```powershell
# View convergence phases
cd Figures/FD/CONVERGENCE/Convergence/

# Each folder: Phase_PHASENAME/TIMESTAMP_N####_Nx_Ny/
# View phase details
dir
```

### Example 3: Finding Specific Parameter Set
```powershell
# Search for files with specific viscosity
cd Figures/FD/SWEEP/
ls -r *nu=1.00e-06* | sort
```

## Configuration

The file organization behavior is controlled by parameters in the `% EDIT THESE` section:

```matlab
figures.root_dir = "Figures";                  % Root directory for all output
figures.save_png = true;                       % Save PNG figures
figures.save_fig = false;                      % Save MATLAB .fig format
figures.dpi = 300;                             % DPI for raster exports
figures.close_after_save = true;               % Close figures after saving
convergence.save_iteration_figures = true;     % Save intermediate figures during convergence
```

## Notes

- Filenames are sanitized to be filesystem-safe (spaces → underscores, special chars removed)
- Directory structure is created automatically if it doesn't exist
- All time values are in UTC local time
- Convergence iteration figures have their own naming scheme for clarity
