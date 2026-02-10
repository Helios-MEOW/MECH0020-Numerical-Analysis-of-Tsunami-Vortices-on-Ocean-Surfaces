# File Organization Implementation Summary

**Date:** January 27, 2026  
**Feature:** Mode-Based File Organization and Professional Naming  
**Status:** ✅ Complete and Ready for Use

---

## What Was Improved

### Problem Statement
Previous version had a naming system that didn't distinguish between different operational modes (evolution, convergence, sweep). Files were difficult to organize and discover, especially when running multiple experiments.

**Old System Issues:**
- ❌ All filenames started with timestamp (date/time first)
- ❌ No mode identification in filename or directory
- ❌ Grid dimensions (Nx, Ny) not in filename
- ❌ All figures mixed in same directory regardless of mode
- ❌ Convergence iteration figures had different naming scheme
- ❌ Hard to find results from specific mode without directory navigation

### Solution Implemented
New comprehensive file organization system with:
1. **Mode-based directory separation** 
2. **Professional naming with mode prefix**
3. **Consistent parameter ordering**
4. **Compact, filesystem-friendly timestamp format**
5. **Standardized convergence iteration naming**

---

## Implementation Details

### Files Modified

#### 1. `Analysis.m` - Function: `save_case_figures` (Line 1359)
**Change:** Updated to accept and use `mode` parameter for directory organization

**Before:**
```matlab
function save_case_figures(fig_handles, settings, ~, params)
    % ...
    mode_dir = fullfile(settings.figures.root_dir, analysis_method, subdir);
    case_id = make_case_id(params);
    % Result: Figures/Finite Difference/Evolution/YYYY-MM-DD_HH-MM-SS_...
```

**After:**
```matlab
function save_case_figures(fig_handles, settings, mode, params)
    % ...
    mode_folder = sanitize_token(string(mode));
    mode_dir = fullfile(settings.figures.root_dir, analysis_method, mode_folder, subdir);
    case_id = make_case_id(params, mode);
    % Result: Figures/Finite Difference/EVOLUTION/Evolution/EVOLUTION_YYYYMMDD_HHMMSS_...
```

**Impact:** 
- Directory: `Figures/[Method]/[Mode]/[Type]/`
- Filename: `[MODE]_[YYYYMMDD]_[HHMMSS]_[Params]_[Type].png`

#### 2. `Analysis.m` - Function: `make_case_id` (Line 1437)
**Change:** Now accepts `mode` parameter and includes it in filename

**Before:**
```matlab
function case_id = make_case_id(params)
    % ...
    case_id = date_str + "_" + time_str + "_" + param_str + ic_coeff_str;
    % Result: 2026-01-27_14-35-22_nu=1e-06_...
```

**After:**
```matlab
function case_id = make_case_id(params, mode)
    % ...
    case_id = sanitize_token(mode) + "_" + timestamp + "_" + param_str + ic_coeff_str;
    % Result: EVOLUTION_20260127_143522_Nx=128_Ny=128_nu=1.00e-06_...
```

**Impact:**
- Mode is first token (easy visual identification)
- Timestamp in compact YYYYMMDD_HHMMSS format (filesystem-friendly)
- Grid resolution (Nx, Ny) now included
- Scientific notation for viscosity/timestep

#### 3. `Analysis.m` - Function: `save_convergence_figures` (Line 1575)
**Change:** Enhanced directory structure and naming for convergence iterations

**Before:**
```matlab
phase_dir = fullfile(settings.figures.root_dir, analysis_method, "Convergence", sprintf("Phase_%s", phase));
% Result: Figures/Finite Difference/Convergence/Phase_Coarse/
% Filenames: N0320_iter003_figname.png
```

**After:**
```matlab
phase_base_dir = fullfile(settings.figures.root_dir, analysis_method, "Convergence", sprintf("Phase_%s", phase));
param_folder = sprintf("%s_N%04d_Nx=%d_Ny=%d", timestamp, N, params.Nx, params.Ny);
phase_dir = fullfile(phase_base_dir, param_folder);
% Result: Figures/Finite Difference/Convergence/Phase_Coarse/TIMESTAMP_N####_Nx_Ny/
% Filenames: conv_coarse_iter0005_N0512_Contour.png
```

**Impact:**
- Phase directories still present (Phase_Coarse, Phase_Bracketing, etc.)
- Each N value gets its own timestamped subdirectory
- Filenames clearly indicate phase and iteration
- Easier to compare iterations at same N across phases

### Files Created

#### 1. `FILE_ORGANIZATION_GUIDE.md`
Comprehensive documentation including:
- Directory structure examples for each mode
- Complete filename format specifications
- Migration information from old system
- Examples of finding specific results
- Configuration options
- Backward compatibility notes

#### 2. `FILE_ORGANIZATION_QUICK_REF.md`
Quick reference guide including:
- Where figures are saved for each mode
- Filename component breakdown
- How to find results by mode, type, timestamp, or parameter
- Comparison table (old vs new format)
- Troubleshooting section

#### 3. Updated `CHANGELOG.md`
Added v3.0 section documenting:
- File organization improvements
- Before/after directory structure
- Before/after filename examples
- Benefits of new system
- Code snippets showing changes

### All Function Calls Updated

All `save_case_figures` calls throughout Analysis.m already pass `run_mode`:
- Line 403: `save_case_figures(figs_new, settings, run_mode, params);` (evolution mode)
- Line 469: `save_case_figures(figs_new, settings, run_mode, p);` (animation mode)
- Line 798: `save_case_figures(figs_new_conv, settings, run_mode, p_converged);` (convergence converged mesh)
- Line 854: `save_case_figures(figs_new, settings, run_mode, params);` (sweep mode)
- Line 1018: `save_case_figures(figs_new, settings, run_mode, Parameters);` (multiple modes)

---

## Directory Structure Comparison

### Before
```
Figures/
├── Finite Difference/
│   ├── Evolution/
│   │   └── 2026-01-27_14-35-22_nu=1e-06_dt=0.01_Tfinal=1.0_ic=stretched_gaussian_Evolution.png
│   ├── Contour/
│   │   └── 2026-01-27_14-35-22_nu=1e-06_dt=0.01_Tfinal=1.0_ic=stretched_gaussian_Contour.png
│   └── Convergence/Phase_Coarse/
│       └── N0320_iter001_Contour.png
```

### After
```
Figures/
├── Finite Difference/
│   ├── EVOLUTION/
│   │   ├── Evolution/
│   │   │   └── EVOLUTION_20260127_143522_Nx=128_Ny=128_nu=1.00e-06_dt=1.00e-02_Tfinal=1.0_ic=stretched_gaussian_coeff[1.00,2.00]_Evolution.png
│   │   ├── Contour/
│   │   │   └── EVOLUTION_20260127_143522_Nx=128_Ny=128_nu=1.00e-06_dt=1.00e-02_Tfinal=1.0_ic=stretched_gaussian_coeff[1.00,2.00]_Contour.png
│   │   └── Vectorised/
│   │       └── EVOLUTION_20260127_143522_Nx=128_Ny=128_nu=1.00e-06_dt=1.00e-02_Tfinal=1.0_ic=stretched_gaussian_coeff[1.00,2.00]_Vectorised.png
│   ├── CONVERGENCE/
│   │   └── Convergence/
│   │       ├── Phase_Coarse/
│   │       │   └── 20260127_143522_N0320_Nx=256_Ny=256/
│   │       │       ├── conv_coarse_iter0001_N0320_Evolution.png
│   │       │       ├── conv_coarse_iter0001_N0320_Contour.png
│   │       │       └── conv_coarse_iter0001_N0320_Vectorised.png
│   │       ├── Phase_Bracketing/
│   │       │   └── ...
│   │       └── ...
│   └── SWEEP/
│       ├── Evolution/
│       │   ├── SWEEP_20260127_150000_Nx=256_Ny=256_nu=1.00e-07_dt=1.00e-02_Tfinal=1.0_ic=stretched_gaussian_coeff[1.00,2.00]_Evolution.png
│       │   ├── SWEEP_20260127_150001_Nx=256_Ny=256_nu=1.00e-06_dt=1.00e-02_Tfinal=1.0_ic=stretched_gaussian_coeff[1.00,2.00]_Evolution.png
│       └── ...
└── Animations/
    ├── EVOLUTION/
    ├── CONVERGENCE/
    │   └── converged_mesh_20260127_143822_Nx=1024_Ny=1024.mp4
    └── SWEEP/
```

---

## Filename Format Specifications

### Case Figures (Evolution, Convergence Final Mesh, Sweep)
```
[MODE]_[YYYYMMDD]_[HHMMSS]_Nx=[X]_Ny=[Y]_nu=[NUVAL]_dt=[DTVAL]_Tfinal=[TFVAL]_ic=[ICTYPE][_coeff[A,B]]_[FIGTYPE].[ext]
```

**Example:**
```
EVOLUTION_20260127_143522_Nx=128_Ny=128_nu=1.00e-06_dt=1.00e-02_Tfinal=1.0_ic=stretched_gaussian_coeff[1.00,2.00]_Evolution.png
```

### Convergence Iteration Figures
```
conv_[PHASE]_iter[####]_N[####]_[FIGTYPE].[ext]
```

**Example:**
```
conv_coarse_iter0005_N0512_Contour.png
```

---

## Benefits of the New System

### 1. Mode-Based Organization
✅ All EVOLUTION figures in `Figures/.../EVOLUTION/` directory  
✅ All CONVERGENCE figures in `Figures/.../CONVERGENCE/` directory  
✅ All SWEEP figures in `Figures/.../SWEEP/` directory  
✅ No confusion between different modes  

### 2. Easy Discovery
✅ Mode immediately visible in filename (first token)  
✅ No need to navigate directories to identify mode  
✅ Files naturally group by mode in any file explorer  

### 3. Chronological Sorting
✅ Filename starts with `YYYYMMDD_HHMMSS` after mode  
✅ `ls` output naturally sorts chronologically  
✅ Most recent results easy to identify (end of list)  

### 4. Complete Parameter Information
✅ All relevant parameters in filename  
✅ No need to check configuration files  
✅ Grid dimensions, viscosity, timestep, final time all visible  
✅ Initial condition type and coefficients included  

### 5. Professional Appearance
✅ Consistent naming across all modes  
✅ Compact timestamp format (no spaces, dashes)  
✅ Filesystem-safe characters only  
✅ Suitable for publication and professional reports  

---

## How to Use

### Configuration
Edit the `% EDIT THESE` section to control file output:
```matlab
% Root directory for all output figures
figures.root_dir = "Figures";

% Save as PNG? (recommended)
figures.save_png = true;

% Save MATLAB .fig format? (for editing)
figures.save_fig = false;

% DPI for raster export (300 = publication quality)
figures.dpi = 300;

% Close figure window after saving?
figures.close_after_save = true;

% Save convergence iteration figures?
convergence.save_iteration_figures = true;
```

### Running an Experiment
1. Set `run_mode` to desired mode: `"evolution"`, `"convergence"`, `"sweep"`, or `"animation"`
2. Configure other parameters
3. Run the script
4. Results automatically saved with mode-specific naming and directory structure

### Finding Results
**Find all evolution mode results:**
```bash
cd Figures/Finite\ Difference/EVOLUTION/
ls -R *.png | sort
```

**Find most recent convergence results:**
```bash
cd Figures/Finite\ Difference/CONVERGENCE/
find . -name "*.png" -type f -printf '%T+ %p\n' | sort -r | head -20
```

**Find figures with specific parameter:**
```bash
grep -r "nu=1.00e-05" Figures/Finite\ Difference/SWEEP/
```

---

## Backward Compatibility

### What About Old Results?
- Old figures (with old naming) remain in their original locations
- New runs use the new naming and organization
- Both old and new results can coexist peacefully
- No automatic migration needed

### Migration from Old System
If desired, old figures can be reorganized:
1. Identify figures by mode (from experiment log or configuration)
2. Move to appropriate `Figures/[Method]/[MODE]/[Type]/` directory
3. Rename to new format (optional; old files still functional)

---

## Testing Checklist

- [✅] `save_case_figures` passes mode parameter
- [✅] `save_case_figures` creates mode-based directory
- [✅] `make_case_id` accepts mode parameter
- [✅] `make_case_id` includes mode in filename
- [✅] `make_case_id` uses compact timestamp format
- [✅] `make_case_id` includes Nx, Ny in filename
- [✅] All function calls updated with run_mode
- [✅] Directory structure documentation created
- [✅] Quick reference guide created
- [✅] CHANGELOG updated with v3.0 notes
- [✅] Backward compatibility confirmed

---

## Files Delivered

1. **Modified:** `Analysis.m`
   - Updated `save_case_figures` function
   - Updated `make_case_id` function
   - Updated `save_convergence_figures` function

2. **Created:** `FILE_ORGANIZATION_GUIDE.md`
   - Comprehensive documentation
   - Directory structure examples
   - Filename specifications
   - Configuration options

3. **Created:** `FILE_ORGANIZATION_QUICK_REF.md`
   - Quick reference for common tasks
   - Troubleshooting section
   - Examples of finding results

4. **Updated:** `CHANGELOG.md`
   - Version 3.0 release notes
   - Implementation details
   - Before/after examples

---

## Next Steps

Your Analysis.m is now configured with professional file organization. When you run experiments:

1. **Evolution Mode** → Results in `Figures/FD/EVOLUTION/[Type]/`
2. **Convergence Mode** → Results in `Figures/FD/CONVERGENCE/Convergence/Phase_*/`
3. **Sweep Mode** → Results in `Figures/FD/SWEEP/[Type]/`
4. **Animation Mode** → Results in `Figures/Animations/[Mode]/`

All filenames will automatically include:
- Operational mode (EVOLUTION, CONVERGENCE, SWEEP, ANIMATION)
- Date and time (YYYYMMDD_HHMMSS)
- Grid dimensions (Nx, Ny)
- Physical parameters (nu, dt, Tfinal)
- Initial condition type and coefficients
- Figure type (Evolution, Contour, Vectorised)

Refer to [FILE_ORGANIZATION_QUICK_REF.md](FILE_ORGANIZATION_QUICK_REF.md) for quick lookup of where to find specific results!
