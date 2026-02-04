# Tsunami Vortex Simulation - Professional Qt Interface

**Version 2.0** - Complete Professional Implementation for Desktop

A professional-grade desktop application for simulating vortex dynamics in tsunami and ocean surface phenomena using multiple numerical methods.

## Features

### Core Simulation Capabilities
- **Multiple Numerical Methods**
  - Finite Difference (FD): 2nd order accurate, stable, efficient
  - Finite Volume (FV): Conservative, excellent for discontinuities
  - Spectral (Fourier): High accuracy for smooth flows
  - Variable Bathymetry: Coupling with seafloor topography

- **Comprehensive Initial Conditions**
  - Lamb-Oseen: Classical diffusing vortex
  - Rankine: Solid rotation core + irrotational exterior
  - Taylor-Green: Doubly periodic vorticity field
  - Lamb Dipole: Propagating vortex pair
  - Elliptical Vortex: Non-circular core profiles
  - Random Turbulence: Realistic energy spectra

- **Multi-Vortex Support**
  - Single vortex at domain center
  - Grid pattern: Regular NxNy arrangement
  - Circular pattern: Radial distribution
  - Random distribution: Stochastic placement

### Professional Interface
- Real-time IC preview with contour plots
- Live parameter adjustment with instant visualization
- Multi-threaded simulation (non-blocking UI)
- Professional COMSOL-inspired color scheme
- Responsive 3-panel layout (Workflow | Visualization | Parameters)

### Results Analysis
- Metrics visualization (Energy, Enstrophy, Vorticity)
- Multi-run history tracking
- Export capabilities (HDF5, CSV, JSON)
- Performance metrics display

### Configuration Management
- Auto-save/restore last configuration
- Preset configurations for common scenarios
- Easy parameter tuning and validation

## Installation

### Prerequisites
- Python 3.8+
- PySide6 (Qt for Python)
- NumPy
- SciPy
- Matplotlib
- MATLAB Engine for Python (optional, uses mock engine if unavailable)

### Setup
```bash
# Clone or navigate to the tsunami_ui directory
cd tsunami_ui

# Install dependencies
pip install PySide6 numpy scipy matplotlib

# Optional: Install MATLAB Engine for Python
pip install matlabengine
```

## Usage

### Starting the Application
```bash
python main.py
```

### Workflow
1. **Select Method**: Choose numerical scheme (FD, FV, Spectral)
2. **Configure Initial Condition**: Select vortex type and pattern
3. **Set Domain**: Specify domain size (Lx, Ly) and grid resolution
4. **Time Parameters**: Set dt, final time T, and viscosity ν
5. **Vortex Pattern**: Choose arrangement for multiple vortices
6. **Execute**: Click "Run Simulation" to start
7. **Analyze**: View metrics, energy, and convergence plots
8. **Export**: Save results in HDF5, CSV, or JSON format

### Key Parameters

| Parameter | Range | Default | Notes |
|-----------|-------|---------|-------|
| Grid Size (N) | 32-512 | 128 | Must be power of 2 for spectral |
| Domain Size (Lx, Ly) | 1-100 | 10 | Physical domain dimensions |
| Time Step (dt) | 0.0001-0.1 | 0.001 | CFL stability required |
| Final Time (T) | 0.1-1000 | 10 | Total simulation time |
| Viscosity (ν) | 0-1 | 0.0001 | Must be non-negative |
| Number of Vortices | 1-10 | 1 | For multi-vortex ICs |

## Architecture

### Modules
- **main.py**: Application entry point, QApplication initialization
- **ui/main_window.py**: Main interface with 3-panel layout, threading
- **ui/config_manager.py**: Configuration save/load/presets
- **ui/results_analyzer.py**: Results visualization and export
- **matlab_interface/engine_manager.py**: MATLAB bridge (real or mock)
- **utils/dispersion.py**: Multi-vortex dispersion patterns

### Threading Model
- **SimulationThread**: Background execution of simulations
- **ICPreviewThread**: Non-blocking IC preview generation
- Main UI thread remains responsive during long operations

## Examples

### Quick Test (1 minute)
```
Method: Finite Difference
IC: Lamb-Oseen, Single vortex
Grid: 6464
Time: 1.0 s
```

### Standard Convergence Study
```
Method: Finite Difference
IC: Lamb-Oseen, Grid pattern (22)
Grid: 128128
Time: 10.0 s
```

### High-Resolution Spectral
```
Method: Spectral
IC: Lamb-Oseen, Circular pattern (6 vortices)
Grid: 256256
Time: 10.0 s
```

## Performance Notes
- Spectral method is fastest for smooth ICs (use for development)
- Finite Volume is most conservative (use for production)
- Multi-threaded design prevents UI freezing
- Mock MATLAB engine enables testing without MATLAB installation

## Integration with MATLAB Codebase
The Qt application integrates with the existing MATLAB analysis framework:
- Calls: Scripts/Methods/Finite_Difference_Analysis.m, etc.
- IC Generation: Scripts/Initial_Conditions/*.m
- Infrastructure: Scripts/Infrastructure/disperse_vortices.m
- Results: Loads from Scripts/Main/Cache/

## Future Enhancements
- [ ] Parameter sensitivity analysis
- [ ] GPU acceleration (CUDA)
- [ ] Real-time video export
- [ ] Advanced convergence studies
- [ ] Publication-quality figure export
- [ ] Data assimilation module
- [ ] Real-time bathymetry import

## Troubleshooting

### MATLAB Engine Not Found
The application automatically uses a mock engine. Real MATLAB requires:
```bash
pip install matlabengine
```

### Slow Preview Generation
IC preview is computed in background thread. Try:
- Reducing grid size (6464 instead of 256256)
- Using simpler IC types (Rankine vs. Taylor-Green)

### Memory Issues
- Reduce grid size for large simulations
- Use lower-order methods (FD before Spectral)
- Increase time steps cautiously (watch CFL criterion)

## References
- Lamb-Oseen: Classical vortex diffusion (Lamb 1932)
- Rankine: Solid body rotation model
- Taylor-Green: Doubly periodic solution
- Finite Volume: Conservative numerical discretization
- Spectral Methods: Fourier-based high-accuracy schemes

## License
[Your License Here]

## Contact
For questions or issues, contact the project maintainers.
