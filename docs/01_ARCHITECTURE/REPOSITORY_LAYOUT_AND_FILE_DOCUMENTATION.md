# MECH0020 Repository Structure and File Documentation

**Project:** Numerical Analysis of Tsunami Vortices on Ocean Surfaces  
**Institution:** University College London  
**Date:** February 2026  
**Total Files:** 40+ MATLAB scripts, 6+ Python files  
**Architecture:** Modular MATLAB backend with Python UI frontend

---

##  Repository Overview

The repository is organized into 6 main sections:

\\\
MECH0020-Numerical-Analysis-of-Tsunami-Vortices-on-Ocean-Surfaces/
 Scripts/                    # Core computational engine (MATLAB)
    Main/                   # Entry points and workflow orchestration
    Methods/                # 4 independent numerical solvers
    Infrastructure/         # Shared utilities and factories
    Initial_Conditions/     # 6 IC types with multi-vortex support
    UI/                     # MATLAB graphical interface
    Visuals/                # Visualization and monitoring
    Sustainability/         # Energy analysis, hardware monitoring
 utilities/                  # OWL plotting framework + helpers
 tsunami_ui/                 # Python Qt professional UI (Phase 3)
 Results/                    # Output storage (CSV, MAT, figures)
 docs/                       # Project documentation
 [ROOT FILES]               # Configuration and README
\\\

---

##  Scripts/ Directory (Computational Core)

### Main/ - Workflow Orchestration

**Analysis.m** (~ 400 lines)
- **Purpose:** Primary entry point for the entire simulation framework
- **Functionality:**
  - Startup dialog: offers UI Mode vs Traditional Mode
  - Parameter initialization (default or custom)
  - Selects execution mode (evolution/convergence/sweep)
  - Calls appropriate backend solvers
  - Manages result collection and logging
- **Key Functions:**
  - User mode selection
  - Parameter validation
  - Logging initialization
  - Result aggregation
- **Called By:** User or test scripts
- **Calls:** UIController, run_simulation_with_method, extract_unified_metrics
- **Output:** Simulation results, figures, CSV/MAT logs

**AdaptiveConvergenceAgent.m** (~ 300 lines)
- **Purpose:** Adaptive grid refinement algorithm for convergence studies
- **Functionality:**
  - Progressive grid refinement (N=32  64  128  256  512)
  - Automatic convergence criterion detection
  - Error estimation between refinement levels
  - Adaptive stopping (when convergence achieved)
  - Detailed convergence metrics logging
- **Key Functions:**
  - run_adaptive_convergence()
  - estimate_convergence_rate()
  - check_stopping_criteria()
- **Called By:** Analysis.m (when mode = 'convergence')
- **Calls:** run_simulation_with_method
- **Output:** Convergence plots, rate estimates, refinement history

---

### Methods/ - Numerical Solvers (4 Independent Methods)

**Finite_Difference_Analysis.m** (~ 600 lines)
- **Purpose:** Strictly finite difference vorticity-streamfunction solver with Arakawa Jacobian
- **Key Features:**
  - Vorticity-streamfunction formulation: $\frac{\partial \omega}{\partial t} + u\frac{\partial \omega}{\partial x} + v\frac{\partial \omega}{\partial y} = \nu \nabla^2 \omega$
  - 2nd-order finite difference discretization on Cartesian grid
  - Arakawa Jacobian operator (energy-conserving advection)
  - Elliptic Poisson solver: sparse matrix solve ($\nabla^2 \psi = -\omega$) via `A \ omega`
  - Explicit time stepping (RK4)
  - Periodic boundary conditions (shift operators)
- **Key Functions:**
  - rhs_fd_arakawa() - Computes RHS using Arakawa 3-point scheme
  - Poisson solve via sparse matrix inversion (A \ omega)
  - Velocity recovery using finite difference shifts
- **Parameters:** N (grid), Lx/Ly (domain), T (time), dt (timestep), nu (viscosity)
- **Output:** Vorticity field ω(x,y,t), streamfunction ψ(x,y,t), kinetic energy, enstrophy
- **Complexity:** O(N²) per timestep (sparse matrix solve, not FFT)

**Spectral_Analysis.m** (~ 500 lines)
- **Purpose:** Fourier spectral methods for high-order accuracy
- **Key Features:**
  - Full spectral expansion (Fourier basis)
  - Galerkin projection for dynamics
  - Exponential convergence with N
  - Ideal for smooth IC (Lamb-Oseen, Rankine)
  - Lower resolution needed than FD for same accuracy
- **Key Functions:**
  - spectral_vorticity_streamfunction()
  - compute_spectral_jacobian()
  - fft_based_derivatives()
  - spectral_rk4_step()
- **Parameters:** N_modes (spectral), T, dt
- **Output:** Spectral coefficients, reconstructed field
- **Complexity:** O(N log N) per step, but N often 50-100 vs FD 128-512

**Finite_Volume_Analysis.m** (~ 550 lines)
- **Purpose:** Conservative finite volume formulation
- **Key Features:**
  - Flux-based advection (conservative)
  - Volume-averaged quantities
  - Second-order spatial accuracy (with limiters)
  - Better for discontinuities (shock-like features)
  - Godunov-type reconstruction
- **Key Functions:**
  - fv_vorticity_streamfunction()
  - compute_flux_jacobian()
  - fv_reconstruction()
  - update_volume_averages()
- **Parameters:** N, Lx/Ly, T, dt, limiter_type
- **Output:** Volume-averaged vorticity, mass-conserving flux
- **Use Case:** Non-smooth features, conservation verification

**Variable_Bathymetry_Analysis.m** (~ 700 lines)
- **Purpose:** Vortex dynamics over variable bottom topography
- **Key Features:**
  - Variable bathymetry h(x,y) modifies dynamics
  - Shallow water vorticity equations
  - Topographic forcing via $\nabla \times (\nabla h  u)$
  - Pre-configured bathymetry profiles:
    - Flat bottom (h = const)
    - Gaussian bump (h = h - H exp(-(x + y)/σ))
    - Slope/shelf (h = h + αx)
    - Canyon (h = h - Δh tanh(x/W))
  - Interaction and reflection effects
- **Key Functions:**
  - bathymetry_vortex_dynamics()
  - get_bathymetry_field()
  - compute_topographic_forcing()
  - apply_bathymetry_bc()
- **Parameters:** N, bathymetry_type, h_profile_params, T, dt
- **Output:** Vorticity with bathymetry effects, energy dissipation/transfer
- **Use Case:** Realistic tsunami scenarios with underwater terrain

**Supporting Methods Files:**

**run_simulation_with_method.m** (~ 400 lines)
- **Purpose:** Unified interface for all 4 methods
- **Function Signature:**
  `matlab
  [omega, psi, time, energy, metrics] = run_simulation_with_method(params, method_name)
  `
- **Logic:**
  - Parses method_name ('FD', 'FV', 'Spectral', 'Bathymetry')
  - Validates parameters for that method
  - Calls appropriate analysis function
  - Collects metrics during evolution
  - Returns unified data structure
- **Key Contribution:** Abstraction layer so UI doesn't know method details

**run_simulation_with_method_enhanced.m** (~ 450 lines)
- **Purpose:** Extended version with parameter sweeps and batch processing
- **Enhancements:**
  - Parameter sweep capability (vary one parameter, run N simulations)
  - Parallel execution (if Parallel Computing Toolbox available)
  - Batch job management
  - Result aggregation and comparison
  - Multi-method comparison (run same IC on all 4 methods)

**extract_unified_metrics.m** (~ 300 lines)
- **Purpose:** Post-processing analysis of simulation results
- **Metrics Calculated:**
  - Kinetic energy:  = \frac{1}{2}\int (u^2 + v^2) dA$
  - Enstrophy:  = \frac{1}{2}\int \omega^2 dA$
  - Palinstrophy:  = \frac{1}{2}\int |\nabla \omega|^2 dA$
  - Circulation: $\Gamma = \oint \omega dA$
  - Vortex core radius and strength
  - Spectral energy distribution
  - Convergence rates
- **Output:** Unified metrics struct with timeseries

**mergestruct.m** (~ 50 lines)
- **Purpose:** Utility to recursively merge MATLAB structs
- **Used By:** Parameter merging, result aggregation
- **Handles:** Nested structs, overwrite policies

---

### Infrastructure/ - Shared Utilities

**ic_factory.m** (~ 250 lines)
- **Purpose:** Factory pattern for generating initial conditions
- **Supported IC Types:**
  1. **Lamb-Oseen:** $\omega = \frac{\Gamma}{\pi r_c^2} e^{-r^2/r_c^2}$ (smooth Gaussian core)
  2. **Rankine vortex:** $\omega = \begin{cases} \frac{\Gamma}{\pi r_c^2} & r < r_c \\ 0 & r \geq r_c \end{cases}$ (uniform core)
  3. **Taylor-Green:**  = -\cos(kx)\sin(ky)$,  = \sin(kx)\cos(ky)$ (periodic pattern)
  4. **Lamb dipole:** Dipole structure $\psi = -U_0 R \frac{J_1(k_1 r)}{J_1(k_1 R)} \sin\theta$
  5. **Elliptical vortex:** Generalized vortex with elliptical symmetry
  6. **Random turbulence:** Pseudo-random superposition of modes
- **Multi-Vortex Support:** All 6 types support n_vortices parameter
- **Dispersion Patterns:**
  - Single (n=1): centered at origin
  - Circular: n vortices on circle of radius r
  - Grid: n vortices in grid pattern
  - Random: random positions with minimum separation
- **Function Signature:**
  `matlab
  [omega, x, y] = ic_factory(ic_type, params, n_vortices, dispersion_type)
  `

**disperse_vortices.m** (~ 200 lines)
- **Purpose:** Vortex spatial distribution engine
- **Patterns:**
  - **circular(n, radius):** evenly spaced on circle
  - **grid(n, Lx, Ly):** rectangular grid pattern
  - **random(n, Lx, Ly, min_dist):** Poisson-disk sampling with minimum separation
  - **line(n, length):** linear arrangement
- **Output:** Center positions [x, y] for each vortex

**validate_simulation_parameters.m** (~ 150 lines)
- **Purpose:** Input validation before simulation
- **Checks:**
  - Domain size validity (Lx, Ly > 0)
  - Grid resolution validity (N must be positive integer)
  - Time parameters (T > 0, dt < T)
  - Stability criteria (CFL condition)
  - Physical parameters (nu > 0)
  - Method compatibility (check params for selected method)
- **Output:** Boolean valid, error messages array

**create_default_parameters.m** (~ 120 lines)
- **Purpose:** Generate parameter struct with sensible defaults
- **Default Configuration:**
  - Method: 'FD'
  - IC type: 'lamb_oseen'
  - Grid: N=128, Lx=10, Ly=10
  - Time: T=5, dt=0.01
  - Physics: Re=1000, Gamma=1
- **Customizable:** User can override any parameter

**initialize_directory_structure.m** (~ 80 lines)
- **Purpose:** Create output directory hierarchy
- **Creates:**
  - Results/Figures/
  - Results/Data/
  - Results/Logs/
  - Results/Cache/
- **Ensures:** Consistency across runs

---

### Initial_Conditions/ - 6 IC Generation Functions

Each file implements one IC type and supports multi-vortex dispersion.

**ic_lamb_oseen.m** (~ 100 lines)
- **Smooth Gaussian vortex core**
- **Equation:** $\omega(r) = \frac{\Gamma}{\pi r_c^2} \exp(-r^2/r_c^2)$
- **Properties:** Smooth, infinite extent, good for spectral
- **Parameters:** Gamma (circulation), rc (core radius)

**ic_rankine.m** (~ 100 lines)
- **Uniform vorticity core**
- **Equation:** $\omega = \begin{cases} \Omega & r < r_c \\ 0 & r \geq r_c \end{cases}$
- **Properties:** Sharp discontinuity, compact support
- **Parameters:** Omega (angular velocity), rc (core radius)

**ic_taylor_green.m** (~ 90 lines)
- **Periodic vortex pattern**
- **Equation:**  = -U_0 \cos(kx)\sin(ky)$,  = U_0 \sin(kx)\cos(ky)$
- **Vorticity:** $\omega = 2U_0 k \sin(kx + ky)$
- **Properties:** Periodic, no net circulation, test of domain periodicity
- **Parameters:** U0 (velocity scale), k (wavenumber)

**ic_lamb_dipole.m** (~ 120 lines)
- **Two-vortex dipole structure**
- **Model:** Bessel function solution $\psi = -U_0 R \frac{J_1(k_1 r)}{J_1(k_1 R)} \sin\theta$
- **Properties:** Self-propagating, coherent structure
- **Parameters:** U0 (propagation speed), R (dipole scale)

**ic_elliptical_vortex.m** (~ 110 lines)
- **Generalized elliptical vortex**
- **Parameters:** Major axis a, minor axis b, rotation angle
- **Properties:** Non-circular symmetry, aspect ratio control
- **Equation:** $\omega = \frac{\Gamma}{\pi a b} \exp(-\frac{(x')^2}{a^2} - \frac{(y')^2}{b^2})$

**ic_random_turbulence.m** (~ 140 lines)
- **Pseudo-random superposition of vortex modes**
- **Method:**
  1. Generate N random Fourier modes
  2. Impose divergence-free constraint
  3. Superpose with random weights
  4. Normalize
- **Properties:** Turbulent-like, multiple scales, reproducible (seed-based)
- **Parameters:** Energy spectrum shape, number of modes

---

### UI/ - MATLAB Graphical Interface

**UIController.m** (~ 1600 lines)
- **Purpose:** Professional dark-mode MATLAB App Designer interface
- **Architecture:** Class-based App Designer (App inherits from matlab.apps.AppBase)
- **Key Components:**
  - **9 Tabs:** Setup | IC Viewer | Method | Domain | Advanced | Results | Logs | Cache | Settings
  - **Left Panel:** Workflow navigator + method/mode selection
  - **Center Panel:** Live execution monitoring (2 figures) + IC preview
  - **Right Panel:** Parameter configuration (grid, time, physics)
  - **Bottom:** Readiness checklist + action buttons
  
- **Key Features:**
  - Parameter validation with live feedback
  - IC preview (real-time as user changes parameters)
  - Live execution monitoring (iterations/sec, convergence)
  - Method-specific parameter panels
  - Dark theme ([0.15 0.15 0.15] background, [0.9 0.9 0.9] text)
  - Responsive scaling (AutoResizeChildren='on')
  - Integrated terminal output
  - Results browser
  
- **Methods:**
  - on_method_changed()
  - on_mode_changed()
  - on_ic_type_changed()
  - validate_parameters()
  - run_simulation_clicked()
  - update_ic_preview()
  - update_live_monitor()
  - save_configuration()
  - load_configuration()
  
- **Data Flow:**
  1. User configures parameters in right panel
  2. on_parameter_changed() triggers preview update
  3. IC preview updates in center area
  4. User clicks "Run Simulation"
  5. Parameters passed to run_simulation_with_method()
  6. Results streamed to live monitors
  7. Final results browsable in Results tab

**TEST_UIController.m** (~ 200 lines)
- **Purpose:** Unit tests for UIController functionality
- **Tests:**
  - Parameter validation
  - IC preview generation
  - Method switching
  - Figure rendering
  - Data I/O

**UIController_Test_Documentation.ipynb** (Jupyter Notebook)
- **Purpose:** Interactive documentation of UI testing workflows
- **Contents:** Test scenarios, expected outputs, debug tips

---

### Visuals/ - Visualization and Monitoring

**create_live_monitor_dashboard.m** (~ 350 lines)
- **Purpose:** Real-time execution monitoring dashboard
- **Features:**
  - 2-3 subplot layout for simultaneous monitoring
  - Iterations vs Time plot (simulation progress)
  - Iterations/Second plot (performance tracking)
  - Convergence monitor (optional 3rd plot)
  - Color-coded status indicators
  - Automatic scaling and updating
- **Called By:** run_simulation_with_method during execution
- **Output:** Figure handle for embedding in UI

---

### Sustainability/ - Energy Analysis and Hardware Monitoring

**EnergySustainabilityAnalyzer.m** (~ 300 lines)
- **Purpose:** Energy and computational efficiency analysis
- **Metrics:**
  - Computational cost (flops, wall-time, CPU-time)
  - Memory usage (peak, average)
  - Energy per simulation (estimated from CPU power)
  - Efficiency (useful_work / energy_consumed)
  - Cost per grid point
- **Output:** Efficiency report, cost breakdown, recommendations

**HardwareMonitorBridge.m** (~ 250 lines)
- **Purpose:** Interface between MATLAB and Python hardware monitor
- **Functionality:**
  - Calls hardware_monitor.py to get system stats
  - GPU utilization (if available)
  - CPU temperature, throttling
  - Memory pressure
  - Thermal state
- **Data Exchange:** Via JSON intermediary or memory mapping

**hardware_monitor.py** (~ 200 lines)
- **Purpose:** Python hardware telemetry collection
- **Capabilities:**
  - CPU usage, temperature, frequency
  - Memory (RAM) usage
  - GPU stats (NVIDIA via nvidia-ml-py)
  - Disk I/O
  - Network activity
  - Thermal zones
- **Output:** JSON dict to MATLAB bridge

**iCUEBridge.m** (~ 180 lines)
- **Purpose:** Optional RGB lighting feedback (Corsair iCUE compatible)
- **Feature:** Real-time simulation status visualization on RGB peripherals
- **Colors:**
  - Green: Simulation running normal
  - Yellow: Convergence approaching
  - Red: Unstable/error condition
  - Blue: Idle/waiting
- **Not Critical:** Optional enhancement for visual feedback

**update_live_monitor.m** (~ 150 lines)
- **Purpose:** Continuous update of monitoring displays
- **Called:** Inside time-stepping loops
- **Updates:** Live plots, status bars, telemetry displays

---

##  utilities/ Directory (OWL Plotting Framework)

The utilities folder contains a cohesive "OWL Framework" for professional visualization.

**Plot_Defaults.m** (~ 80 lines)
- **Purpose:** Set global MATLAB plot defaults for consistency
- **Configures:**
  - FontName: 'Courier New' (monospace for code-style)
  - FontSize: 13pt base, 16pt titles
  - LineWidth: 2.5pt (visible on projection)
  - Marker sizes: 8pt
  - Color scheme: colorblind-friendly (Viridis, Turbo)
- **Called:** Once at startup

**Plot_Format.m** (~ 150 lines)
- **Purpose:** Post-processing formatting for individual plots
- **Function Signature:** Plot_Format(ax, title, xlabel, ylabel, varargin)
- **Features:**
  - Adds title, labels with proper spacing
  - Applies grid, ticks, limits
  - Legend formatting
  - Dark background option
  - LaTeX interpreter support
- **Smart Defaults:** Detects plot type (2D/3D/surface) and applies appropriate formatting

**Plot_Format_And_Save.m** (~ 120 lines)
- **Purpose:** Unified formatting + saving workflow
- **Function Signature:** Plot_Format_And_Save(fig, filename, format, varargin)
- **Formats:** PNG, PDF, EPS, SVG
- **Resolution:** 300 DPI for print quality
- **Auto-naming:** Includes timestamp, method name, parameters in filename
- **Workflow:**
  1. Format figure (fonts, colors, labels)
  2. Set paper size and position
  3. Export to multiple formats
  4. Log saved files

**Plot_Saver.m** (~ 100 lines)
- **Purpose:** Intelligent figure caching and file management
- **Features:**
  - Checks if identical plot already saved (via hash)
  - Avoids duplicate saves
  - Organizes by method, date, IC type
  - Maintains CSV index of all saved figures
- **Benefit:** Prevents disk space waste for repeated runs

**Legend_Format.m** (~ 90 lines)
- **Purpose:** Professional legend styling
- **Features:**
  - Position optimization (finds empty quadrant)
  - Font size matching
  - Background transparency
  - Border styling
  - LaTeX labels support

**estimate_data_density.m** (~ 110 lines)
- **Purpose:** Estimate data point density for visualization
- **Used By:** Plotting algorithms to choose appropriate representation
- **Output:** Data density metric (points per unit area)
- **Logic:**
  - For scatter: count points per grid cell
  - For continuous: estimate from functional form
  - Recommends: scatter (density < 0.1), line (0.1-10), surface (> 10)

**display_function_instructions.m** (~ 80 lines)
- **Purpose:** Help/documentation display utility
- **Shows:** Function signatures, parameter explanations, examples
- **Called:** When user types help display_function_instructions

**OWL_UtilitiesGuideApp.mlapp** (GUI Application)
- **Purpose:** Interactive guide to OWL plotting utilities
- **Features:** Visual tutorial, code examples, interactive demos
- **Generated For:** New users learning plotting framework

**release/ subdirectory:**
- **build/:** Compiled standalone executable of OWL guide
- **package/:** Installer for distribution
- **Contains:** README, MCR requirements, build logs

---

##  tsunami_ui/ Directory (Python Qt UI - Phase 3)

Modern professional interface built on PySide6 and Matplotlib.

**Project Structure:**
`
tsunami_ui/
 main.py                          # Entry point
 README.md                        # Phase 3 documentation
 ui/
    main_window.py               # Main window class
    widgets/
       visualization_canvas.py  # Matplotlib embedding
       parameter_panel.py       # Control widgets
    dialogs/
        ic_config_dialog.py      # IC configuration window
 matlab_interface/
    engine_manager.py            # MATLAB Engine wrapper
    data_converter.py            # Python  MATLAB type conversion
 utils/
    latex_renderer.py            # LaTeX equation rendering
    validators.py                # Parameter validation
    constants.py                 # UI constants, colors
 data/
    colormaps/                   # Professional colormaps
    icons/                       # UI icons
 tests/
     test_ui.py                   # Basic UI tests
`

**Phase 3 Status:** Complete
-  3-panel professional layout
-  4 methods selectable (FD, FV, Spectral, Bathymetry)
-  6 IC types with LaTeX equations
-  Real-time IC preview
-  Multi-vortex configuration
-  Mock simulation engine

**main.py:**
`python
# Entry point
if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = TsunamiSimulationWindow()
    window.show()
    sys.exit(app.exec())
`

**Key Components:**
- **main_window.py:** Main UI layout, signal/slot connections
- **visualization_canvas.py:** Embedded Matplotlib with interactive toolbar
- **parameter_panel.py:** Right panel with sliders, spinboxes, dropdowns
- **ic_config_dialog.py:** Modal dialog for IC setup
- **engine_manager.py:** Wraps MATLAB Engine for Python for bidirectional communication
- **data_converter.py:** Converts Python dicts  MATLAB structs
- **latex_renderer.py:** Renders LaTeX equations to images for display
- **validators.py:** Parameter range checking and CFL condition verification

**Upcoming Phases (Roadmap):**
- Phase 4: Real MATLAB integration (currently mock engine)
- Phase 5: Live execution monitoring with progress bars
- Phase 6: Advanced parameter panels (physics, numerics, output)
- Phase 7: Results analysis and export tools
- Phase 8: 3D visualization (VTK/PyVista integration)

---

##  Results/ Directory (Output Storage)

**Organization:**
`
Results/
 Figures/                         # PNG/PDF plots
    FD_20260204_lamb_oseen_N128_t5.png
    Spectral_20260204_rankine_N64_t5.pdf
    ...
 Data/                            # MAT/CSV numerical data
    convergence_study_20260204.mat
    sweep_parameters_reynolds.csv
    ...
 Logs/                            # Execution logs
    simulation_20260204_102530.log
    errors_20260204.log
    ...
 Cache/                           # Cached computation results
    fft_plans/
    mesh_data/
 Sustainability/                  # Energy/efficiency reports
     energy_cost_20260204.csv
     hardware_stats_20260204.log
`

**Auto-Naming Convention:** {method}_{timestamp}_{ic_type}_N{gridsize}_t{time}.{ext}

---

##  docs/ Directory (Documentation)

**markdown_archive/:**
- Historical documentation versions
- Archived design notes
- Previous UI research iterations

---

##  Root-Level Files

**README.md** (~ 200 lines)
- Project overview
- Quick start guide
- Operating modes (UI vs traditional)
- Key features summary
- Installation instructions

**COMPREHENSIVE_TEST_SUITE.m** (~ 400 lines)
- Regression testing
- Tests all 4 methods  6 IC types
- Convergence verification
- Energy conservation checks
- Output validation

**test_method_dispatcher.m** (~ 200 lines)
- Tests run_simulation_with_method dispatcher
- Verifies method routing logic
- Parameter passing verification

**test_ui.m** (~ 150 lines)
- UI component testing
- Parameter validation tests
- Preview rendering tests

**test_ui_startup.m** (~ 100 lines)
- Startup dialog testing
- Mode selection verification
- Initial state checks

**Tsunami_Vortex_Analysis_Complete_Guide.ipynb** (Jupyter Notebook)
- Interactive tutorial notebook
- Complete workflow example
- Code snippets for common tasks
- Result interpretation guide

**UI_Research_And_Redesign_Plan.md** (~ 300 lines)
- Design research summary
- COMSOL/ANSYS analysis
- Qt vs Streamlit comparison
- Implementation roadmap
- Deployment guidelines

**COMPLETE_PROJECT_DOCUMENTATION.md** (~ 400 lines)
- Consolidated project guide
- Repository architecture
- API reference
- Troubleshooting guide
- Developer notes

**chat.json** (Configuration)
- Chat/conversation history
- User preferences
- Session state

---

##  Data Flow and Integration

### Typical Workflow (UI Mode)

`
User Interaction
       
UIController.m (Parameter Input)
       
[Validation: validate_simulation_parameters.m]
       
ic_factory.m  [Generate IC with disperse_vortices.m]
       
IC Preview displayed in UIController
       
[User clicks "Run"]
       
run_simulation_with_method.m
       
Selects: FD / FV / Spectral / Bathymetry
       
Method Analysis runs (e.g., Finite_Difference_Analysis.m)
       
[Live monitoring: update_live_monitor.m + create_live_monitor_dashboard.m]
       
extract_unified_metrics.m  Post-processing
       
Results saved to Results/
       
Sustainability analysis (EnergySustainabilityAnalyzer.m)
       
Plotting using OWL Framework (Plot_Format.m, Plot_Saver.m)
       
Results displayed in Results tab of UIController
`

### Typical Workflow (Traditional Mode)

`
User runs Analysis.m
       
Parameter struct from create_default_parameters.m
       
User modifies parameters via code
       
Loop: for each method in ['FD', 'FV', 'Spectral', 'Bathymetry']
       
  run_simulation_with_method(params, method)
  [Calls specific method analysis]
  [Collects metrics via extract_unified_metrics.m]
  [Logs results]
       
Convergence study via AdaptiveConvergenceAgent.m (optional)
       
All results aggregated and plotted
       
Summary statistics saved to CSV/MAT
`

---

##  Quick Reference: Which File Does What?

| Task | File(s) |
|------|---------|
| Run full simulation (UI) | UIController.m |
| Run full simulation (code) | Analysis.m |
| Configure parameters | create_default_parameters.m, UIController.m |
| Generate initial condition | ic_factory.m, ic_*.m (6 types) |
| Disperse multiple vortices | disperse_vortices.m |
| Run FD simulation | Finite_Difference_Analysis.m  run_simulation_with_method.m |
| Run Spectral simulation | Spectral_Analysis.m  run_simulation_with_method.m |
| Run FV simulation | Finite_Volume_Analysis.m  run_simulation_with_method.m |
| Run over bathymetry | Variable_Bathymetry_Analysis.m  run_simulation_with_method.m |
| Adaptive convergence study | AdaptiveConvergenceAgent.m |
| Extract metrics | extract_unified_metrics.m |
| Plot results professionally | Plot_Format.m, Plot_Format_And_Save.m, Legend_Format.m |
| Save figures efficiently | Plot_Saver.m |
| Monitor live execution | update_live_monitor.m, create_live_monitor_dashboard.m |
| Analyze efficiency | EnergySustainabilityAnalyzer.m |
| Check hardware | HardwareMonitorBridge.m, hardware_monitor.py |
| Validate parameters | validate_simulation_parameters.m |
| Modern Python UI | tsunami_ui/ (Phase 3 complete) |
| Test everything | COMPREHENSIVE_TEST_SUITE.m, test_*.m files |

---

##  Architecture Design Principles

1. **Modular Methods:** 4 numerical methods are completely independent (FD, FV, Spectral, Bathymetry) - can be used separately or compared
2. **Unified Interface:** run_simulation_with_method abstracts all methods behind single interface
3. **Separation of Concerns:** UI (UIController) is decoupled from computation (Methods/)
4. **Factory Pattern:** ic_factory.m generates all initial conditions uniformly
5. **Reusable Infrastructure:** Common utilities (plotting, validation, monitoring) avoid duplication
6. **Scalable UI:** Python UI (tsunami_ui/) is optional, MATLAB UI always available
7. **Post-Processing:** extract_unified_metrics decouples computation from analysis

---

##  Development Status

**Core MATLAB Engine:**  Complete (4 methods, 6 IC types, convergence studies)  
**MATLAB UI (UIController):**  Complete (dark mode, all features)  
**Python UI (tsunami_ui):**  Phase 3 Complete (professional layout, IC preview, mock engine)  
**Testing Suite:**  Comprehensive regression tests  
**Documentation:**  Complete (this file + guides)  

**Next Phases:**
- Phase 4 (tsunami_ui): Real MATLAB integration
- Phase 5: Live monitoring in Python UI
- Phase 6-8: Advanced features and 3D visualization

---

**Document Version:** 1.0  
**Last Updated:** February 2026  
**Maintainer:** MECH0020 Research Team, UCL

