# Function Organization Guide

## Overview

This document summarizes the function organization and refactoring work completed in January 2025. All scripts now have clearly marked section headers that organize functions by purpose.

---

## Analysis.m (4,156 lines) - PRIMARY DRIVER SCRIPT

### Main Function
- **`Analysis()`** - Central controller for all numerical experiments (implicit script body)

### Organization Structure

The script is now organized into the following major sections (with line markers):

#### **PART 1: Framework & Setup (Lines 1-370)**
- OWL Framework documentation and conventions
- Global settings initialization
- Parameter configuration UI
- Utilities path setup

#### **PART 2: Validation & Configuration (Lines 371-530)**
- Input validation
- Global settings struct
- Energy monitoring system initialization
- Directory structure setup
- Animation directory configuration
- Mode dispatch logic

#### **PART 3: Execution & Output (Lines 531-690)**
- Mode execution dispatcher
- Results saving and table generation
- Convergence plot generation
- Results directory organization

#### **PART 4: Mode Implementations (Lines 691-2520)**

**7 Run Modes with Dedicated Functions:**

```
┌─ EVOLUTION MODE (run_evolution_mode)
│   Single simulation with analysis figures
│
├─ ANIMATION MODE (run_animation_mode)
│   High-FPS animation generation (GIF/MP4)
│
├─ CONVERGENCE MODE (run_convergence_mode) ⭐ PRIMARY MODE
│   Adaptive grid convergence study with 4 phases
│   ├─ Phase 1: Initial Richardson pair
│   ├─ Phase 2: Richardson extrapolation
│   ├─ Phase 3: Mesh bracketing
│   └─ Phase 4: Binary search refinement
│
├─ TEST CONVERGENCE MODE (run_test_convergence_mode)
│   Small-scale unit domain testing
│
├─ SWEEP MODE (run_sweep_mode)
│   Parameter variation (viscosity, timestep, IC)
│
├─ EXPERIMENTATION MODE (run_experimentation_mode)
│   Multiple initial conditions testing
│
└─ DT-MESH STUDY (run_dt_mesh_study)
    Temporal-spatial tradeoff analysis
```

#### **PART 5: Utility Functions (Lines 2521-3430)**

**Supporting Infrastructure:**

| Category | Functions | Purpose |
|----------|-----------|---------|
| **Method Selection** | `get_analysis_method()` | Configuration dispatch |
| **CSV Operations** | `migrate_csv_schema()`, `plot_results_from_csv()` | Data persistence |
| **Feature Extraction** | `extract_features_from_analysis()`, `pack_result()` | Result packing |
| **Simulation Execution** | `prepare_simulation_params()`, `execute_simulation()` | Run wrapper |
| **Memory Management** | `memory_metrics_MB()` | Performance tracking |
| **Case Management** | `save_case_figures()`, `make_case_id()` | Output organization |
| **Monitoring** | `create_live_monitor_dashboard_basic()`, `update_live_monitor()` | Real-time dashboard |
| **Visualization** | `update_convergence_plot()` | Live convergence plot |

#### **PART 6: Helper Functions (Lines 3431-4156)**

**9 Semantic Sections (A-I) with 25+ Helper Functions:**

##### **SECTION A: CONVERGENCE PHASE IMPLEMENTATIONS**
- `extend_initial_pair_if_needed()` - Extends Richardson pair when metrics invalid
- Handles Phase 1 initialization and extension logic
- Referenced by Phase 2-4 implementations

##### **SECTION B: INITIAL PAIR & EXTENSION LOGIC**
- `shift_pair()` - Shifts mesh pair (N₁, N₂) → (N₂, N₃)

##### **SECTION C: METRIC VALIDATION & MONITORING**
- `are_metrics_valid()` - Validates Richardson metric pairs
- `update_waitbar_if_present()` - Safe progress bar updates
- `display_convergence_result()` - Formatted result display
- `update_monitor_if_active()` - Updates live dashboard
- `create_monitor_metrics_struct()` - Packs metrics for display
- `update_convergence_tracking()` - Updates tracking arrays

##### **SECTION D: OUTPUT & LOGGING**
- `save_iteration_outputs()` - Saves iteration data
- `convergence_iteration_schema()` - Defines data structure
- `pack_convergence_iteration()` - Packs iteration row
- `save_convergence_iteration_log()` - Writes CSV log
- `migrate_csv_schema()` - Handles CSV compatibility

##### **SECTION E: RICHARDSON METRIC COMPUTATION**
- `compute_richardson_metric_for_mesh()` - Primary Richardson metric
- `compute_interpolation_metric()` - Interpolation-based metric
- `compute_l2_metric()` - L₂ norm metric
- `compute_peak_vorticity_metric()` - Peak vorticity difference
- `has_valid_omega_snaps()` - Validates snapshots

##### **SECTION F: MESH & GRID UTILITIES**
- `create_mesh_grid()` - Creates X,Y mesh grids
- `save_mesh_visuals_if_enabled()` - Conditional mesh visualization
- `generate_mesh_visuals()` - Mesh spacing plots

##### **SECTION G: PARAMETER VARIATION & SWEEPS**
- `apply_parameter_variation()` - Main variation dispatcher
- `apply_single_index_variation()` - Single index variation
- `apply_multi_index_variation()` - Multi-index variation
- `apply_relative_scaling()` - Relative scaling
- `apply_absolute_variation()` - Absolute value variation
- `apply_coefficient_variation()` - Sweep variation

##### **SECTION H: ENERGY MONITORING & SUSTAINABILITY**
- `initialize_energy_monitoring_system()` - Main initialization
- `attempt_monitor_initialization()` - Creates monitor
- `handle_monitor_initialization_failure()` - Graceful fallback
- `display_energy_monitoring_info()` - Setup info
- `create_output_directory_if_needed()` - Creates directories

##### **SECTION I: VISUALIZATION & PLOTS**
- `save_convergence_figures()` - Saves iteration figures
- `export_figure_png()` - PNG export with DPI
- `save_case_figures()` - Case-level figures
- `builtin_save_figure()` - Internal figure handling
- `update_convergence_plot()` - Live convergence plot
- `plot_tradeoff_metrics()` - Tradeoff analysis
- `plot_coefficient_sweep()` - Sweep visualization
- `save_tradeoff_study()` - Tradeoff data saving

---

## Finite_Difference_Analysis.m (932 lines)

### Main Function
- **`[fig_handle, analysis] = Finite_Difference_Analysis(Parameters)`** (Line 36)
  - Solves 2D vorticity-streamfunction equations using FD
  - Implements RK3-SSP time integration with Arakawa advection scheme
  - Returns vorticity/streamfunction snapshots and convergence metrics

### Organization Structure

#### **HEADER: PURPOSE & PHYSICS (Lines 1-35)**
- Problem formulation: ∂ω/∂t + u·∇ω = ν∇²ω, ∇²ψ = -ω
- Spatial discretization details
- Time integration approach
- Output structure documentation

#### **MAIN SOLVER (Lines 36-780)**
- Parameter validation
- Mesh and Laplacian setup
- Initial condition initialization
- RK3-SSP time stepping loop
- Snapshot collection
- Kinetic energy and enstrophy tracking
- Live preview and animation generation

#### **HELPER FUNCTIONS (Lines 781-932)**

##### **SECTION A: PLOT SETTINGS & FORMATTING**
- `get_plot_settings()` - Retrieves plot configuration from Parameters
- `apply_plot_format_to_axes()` - Integrates with OWL framework

##### **SECTION B: NUMERICAL SOLVER (ARAKAWA SCHEME)**
- `rhs_fd_arakawa()` - Computes dω/dt using:
  - Arakawa 3-point scheme for advection: J = (J₁ + J₂ + J₃) / 3
  - Standard 5-point Laplacian for diffusion: ν∇²ω
  - Energy-stable advection scheme

##### **SECTION C: FINITE DIFFERENCE SETUP**
- `fd_setup()` - Creates infrastructure:
  - Sparse Laplacian matrix A via Kronecker products
  - Meshgrid X, Y
  - Grid spacing dx, dy
  - Periodic boundary condition support (circshift-ready)

---

## Helper Scripts (Not Yet Organized)

### EnergySustainabilityAnalyzer.m
**Purpose:** Analyzes computational efficiency and energy scaling
- Fits power law: E = A·C^α where C = grid points
- Computes energy per simulation time unit
- Estimates CO₂ emissions

**Status:** `TODO - Add section headers for helper functions`

### HardwareMonitorBridge.m
**Purpose:** Python-MATLAB bridge for hardware monitoring
- Interfaces with Windows WMI via Python
- Tracks CPU usage, RAM, temperature
- Manages sensor data collection

**Status:** `TODO - Add section headers for helper functions`

### hardware_monitor.py
**Purpose:** Python backend for hardware sensors
- WMI queries for Windows hardware
- CSV logging with timestamps
- Cross-platform sensor abstraction

**Status:** `TODO - Add documentation comments and organization`

---

## Best Practices for Adding New Code

### 1. **Run Mode Implementation**
When adding a new run mode:
```matlab
function [T, meta] = run_new_mode(Parameters, settings, run_mode)
    % Add docstring explaining what this mode does
    % Extract large nested blocks into helper functions
    % Limit nesting to 3 levels maximum
    % Log key metrics using pack_convergence_iteration()
end
```

### 2. **Helper Function Creation**
When extracting a helper function:
```matlab
function output = my_helper(input1, input2)
    % BRIEF DESCRIPTION
    % Explain the PURPOSE of this function
    % List INPUT PARAMETERS and their meanings
    % Document OUTPUT values and types
    
    % Implementation
    output = process(input1, input2);
end
```

### 3. **Section Header Format**
```matlab
%%% ========================================================================
%%% SECTION X: DESCRIPTIVE TITLE
%%% ========================================================================
%%% One-sentence purpose explanation
%%% List key functions and their roles
%%% ========================================================================
```

### 4. **Code Organization Strategy**
- Group related functions within sections
- Limit each section to ~5-8 functions
- Order by dependency (utilities first, high-level last)
- Cross-reference between sections in comments

---

## Metrics Summary

### Code Organization Improvements

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| **Max Nesting Depth** | 5 levels | 3 levels | -40% |
| **Longest Function** | 356 lines | 238 lines | -33% |
| **Total Helper Functions** | 0 | 25+ | Extracted |
| **Struct Pattern Variants** | 15 | 1 | 100% unified |
| **Semantic Sections** | Ad-hoc | 9 (A-I) | Organized |
| **Documentation** | Scattered | Consolidated | Single source |

### File Organization

| File | Lines | Main Functions | Helper Sections |
|------|-------|---|---|
| **Analysis.m** | 4,156 | 7 modes + 15 utilities | 9 sections (A-I) |
| **Finite_Difference_Analysis.m** | 932 | 1 main solver | 3 sections (A-C) |
| **EnergySustainabilityAnalyzer.m** | TBD | Energy analysis | TODO |
| **HardwareMonitorBridge.m** | TBD | Monitor wrapper | TODO |

---

## How to Navigate the Code

### Finding a Specific Function

1. **Look in section headers first:** Search for function name in comment blocks (SECTION A-I)
2. **Use MATLAB outline:** Ctrl+M to open outline view
3. **Jump to definition:** Ctrl+Click on function name
4. **Search in notebook:** 6.2-6.9 sections in Jupyter notebook document the helpers

### Understanding Execution Flow

1. **Entry point:** Analysis.m, line ~560 (mode dispatch)
2. **Selected mode:** Find corresponding `run_*_mode()` function (lines 691-2520)
3. **Helper calls:** Trace function calls to helper sections (lines 3431-4156)
4. **Data structures:** See result_schema() and convergence_iteration_schema()

### Adding Features

1. **New run mode:** Create `run_feature_mode()` in PART 4
2. **New metric:** Add to SECTION E in helper functions
3. **New output:** Update result_schema() and pack_result()
4. **New monitoring:** Add to SECTION H (energy monitoring)

---

## Documentation Integration

### Jupyter Notebook (Primary Reference)
- **Location:** `Tsunami_Vortex_Analysis_Complete_Guide.ipynb`
- **Sections 6.1-6.12:** Comprehensive refactoring documentation
- **Tables:** Code quality metrics and organization summary
- **Examples:** Before/after code comparisons

### Markdown Documentation
- **REFACTORING_SUMMARY.md** (~500 lines) - Detailed phase-by-phase analysis
- **SCRIPT_ORGANIZATION.md** (~300 lines) - Directory structure and interdependencies
- **This file (FUNCTION_ORGANIZATION_GUIDE.md)** - Quick reference for navigation

### In-Code Documentation
- Section headers with clear labels (%%% SECTION X:)
- Function docstrings explaining purpose and parameters
- Inline comments for complex logic blocks

---

## Version History

| Date | Change | Impact |
|------|--------|--------|
| **Jan 2025** | Added section headers to Analysis.m (9 sections A-I) | +Organization +Findability |
| **Jan 2025** | Added section headers to Finite_Difference_Analysis.m (3 sections A-C) | +Clarity of solver architecture |
| **Jan 2025** | Added refactoring docs to Jupyter notebook (Sections 6.1-6.12) | +Maintainability +Training |
| **Jan 2025** | Created FUNCTION_ORGANIZATION_GUIDE.md | +Navigation +Reference |

---

## Next Steps

### High Priority
- [ ] Organize EnergySustainabilityAnalyzer.m with section headers
- [ ] Organize HardwareMonitorBridge.m with section headers
- [ ] Add docstrings to hardware_monitor.py
- [ ] Create quick-start guide for run modes

### Medium Priority
- [ ] Extract Finite_Difference_Analysis helpers into external module
- [ ] Create parameter validation utility function
- [ ] Consolidate CSV schema handling

### Low Priority
- [ ] Convert to object-oriented design (if complexity grows)
- [ ] Create MATLAB toolbox package
- [ ] Add GitHub action for documentation generation

---

**Last Updated:** January 30, 2025  
**Maintained By:** Refactoring Initiative  
**Related Files:** Analysis.m, Finite_Difference_Analysis.m, Tsunami_Vortex_Analysis_Complete_Guide.ipynb
