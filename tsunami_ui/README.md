# Tsunami Vortex Simulation - Professional Qt Interface

A modern, professional desktop application for configuring and running tsunami vortex simulations using Qt (PySide6) and MATLAB as the computational backend.

## Project Status

**Current Phase:** Phase 3 - UI Architecture Implementation (In Progress)

### Completed Steps:
- [x] Multi-vortex IC dispersion support (MATLAB side) - All 6 IC functions updated
- [x] Environment setup (Python 3.14 + PySide6 + Matplotlib + SciPy)
- [x] Project structure and scaffolding
- [x] MATLAB engine manager (with mock support for testing without MATLAB)
- [x] Main window with professional 3-panel layout
- [x] Python vortex dispersion utility matching MATLAB version

### Current Implementation:
- Main application window with 3-panel layout:
  - Left: Workflow navigator (Setup, Execution, Results)
  - Center: Real-time visualization with matplotlib
  - Right: Simulation parameters form

## Installation & Setup

### Prerequisites:
- Python 3.9+ (Python 3.14 tested)
- Windows, macOS, or Linux
- Optional: MATLAB (for full backend integration)

### Step 1: Install Python Packages

```bash
pip install pyside6 matplotlib scipy numpy
```

### Step 2: Install MATLAB Engine for Python (Optional)

If you have MATLAB installed, set up the engine:

```bash
cd "C:\Program Files\MATLAB\R202Xx\extern\engines\python"
python setup.py install
```

Or using pip (requires MATLAB):
```bash
pip install matlab
```

### Step 3: Run the Application

From the project root (tsunami_ui directory):

```bash
python main.py
```

## Project Structure

```
tsunami_ui/
 main.py                          # Application entry point
 ui/                              # User interface modules
    __init__.py
    main_window.py              # Main application window
    panels/                      # Future: Separate panel components
    dialogs/                     # Future: Dialog boxes
 matlab_interface/                # MATLAB integration
    __init__.py
    engine_manager.py            # MATLAB engine manager
    data_converter.py            # Future: Data type conversions
 utils/                           # Utilities
    __init__.py
    dispersion.py               # Vortex dispersion algorithms
    latex_renderer.py           # Future: LaTeX rendering
 README.md
```

## Features

### Current (Phase 3):
-  Professional 3-panel layout (workflow, visualization, parameters)
-  Method selection (FD, FV, Spectral, Variable Bathymetry)
-  6 Initial Condition types with multi-vortex support
-  Grid size and vortex configuration
-  Real-time IC preview with matplotlib
-  Mock simulation engine (testing without MATLAB)
-  Professional COMSOL-inspired color scheme

### Upcoming (Phases 4-8):
- MATLAB engine integration (when MATLAB is available)
- Live execution monitoring with progress bars
- Advanced parameter panels
- Results analysis and export
- 3D visualization (optional VTK integration)
- User manual and video tutorials

## Architecture

### MATLAB Integration:

```

  PySide6 Professional UI (Python)   
  - Real-time parameter inputs       
  - Live matplotlib visualization    
  - IC preview generation            

             
              MATLAB Engine API
              (Bidirectional data flow)
             

   MATLAB Simulation Backend         
  - run_simulation_with_method()     
  - extract_unified_metrics()        
  - All numerical methods            
  - Multi-vortex IC support          

```

## MATLAB Integration (When Available)

The `MATLABEngineManager` class in `matlab_interface/engine_manager.py` handles:

1. **Engine Startup**: Connects to MATLAB engine and adds necessary paths
2. **Parameter Conversion**: Converts Python dicts to MATLAB structs
3. **Simulation Execution**: Calls `run_simulation_with_method()` with MATLAB parameters
4. **Metrics Extraction**: Retrieves and returns analysis results
5. **Mock Support**: Provides testing interface without MATLAB installation

### Example Usage:

```python
from matlab_interface.engine_manager import MATLABEngineManager

# Initialize with MATLAB (if installed)
engine = MATLABEngineManager(matlab_available=True)

# Run simulation
params = {
    'Method': 'Finite Difference',
    'IC_type': 'Lamb-Oseen',
    'N': 128,
    'n_vortices': 3,
    'T': 10.0,
    'Lx': 10.0,
    'Ly': 10.0,
}

fig, metrics = engine.run_simulation(params)
print(f"Energy: {metrics['energy']}")
```

## Multi-Vortex Initial Conditions

All IC functions now support spatial dispersion patterns:

- **single**: Single vortex at origin (default)
- **circular**: Vortices arranged in a circle
- **grid**: Vortices in regular grid pattern (default for multiple)
- **random**: Random positions with minimum separation

### MATLAB IC Function Usage:

```matlab
% Single vortex
params.n_vortices = 1;
omega = ic_lamb_oseen(X, Y, params);

% Multiple vortices in grid
params.n_vortices = 4;
params.vortex_pattern = 'grid';
params.Lx = 10.0;
params.Ly = 10.0;
omega = ic_lamb_oseen(X, Y, params);

% Multiple vortices in circle
params.n_vortices = 5;
params.vortex_pattern = 'circular';
omega = ic_rankine(X, Y, params);
```

### Python Utility Usage:

```python
from utils.dispersion import disperse_vortices_py

# Get 4 vortex positions in grid
positions = disperse_vortices_py(4, 'grid', 10.0, 10.0)
# Returns: [(-3.33, -3.33), (3.33, -3.33), (-3.33, 3.33), (3.33, 3.33)]

# Get 5 vortex positions in circle
positions = disperse_vortices_py(5, 'circular', 10.0, 10.0)
```

## Development Roadmap

### Phase 4: MATLAB Integration (1 week)
- [ ] Test MATLAB Engine connection
- [ ] Parameter struct conversion
- [ ] Real simulation execution

### Phase 5: LaTeX Integration (1 week)
- [ ] Configure Matplotlib for LaTeX
- [ ] IC equation display in tooltips
- [ ] Axis label rendering

### Phase 6: Advanced Features (1 week)
- [ ] Live progress monitoring
- [ ] Results analysis panel
- [ ] Export functionality

### Phase 7: Testing & Refinement (2 weeks)
- [ ] Comprehensive test suite
- [ ] Performance optimization
- [ ] Bug fixes and polishing

### Phase 8: Documentation (1 week)
- [ ] User manual
- [ ] Video tutorials
- [ ] API documentation

## Known Issues

1. **MATLAB Not Currently Installed**: Application uses mock engine for testing
2. **LaTeX Rendering**: Currently uses basic matplotlib rendering (will upgrade in Phase 5)
3. **3D Visualization**: Not yet implemented (planned for future enhancement)

## Performance Notes

- UI is responsive even during long simulations (background thread)
- Real-time IC preview works smoothly up to 512512 grids
- Mock simulation completes instantly (for testing without MATLAB)

## Contributing

When adding new features:
1. Update the progress todo list in this README
2. Add docstrings to all functions
3. Test with both mock engine (always) and real MATLAB (when available)
4. Update the development roadmap

## License

This project is part of the MECH0020 course at University College London.

## Support & Issues

For issues or questions:
1. Check the [Tsunami_Vortex_Analysis_Complete_Guide.ipynb](../Tsunami_Vortex_Analysis_Complete_Guide.ipynb)
2. Review [UI_Research_And_Redesign_Plan.md](../UI_Research_And_Redesign_Plan.md)
3. Check matplotlib documentation for visualization issues
4. See MATLAB Engine documentation for integration issues

---

**Last Updated:** February 3, 2026  
**Current Version:** 0.3 (Pre-Alpha)  
**Developer:** Automated Implementation  
**Status:** Phase 3 - Continuing to Phase 4
