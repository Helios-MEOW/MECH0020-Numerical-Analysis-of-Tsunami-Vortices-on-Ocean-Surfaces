# UI Research & Redesign Plan
## Professional Interface for Tsunami Vortex Simulation

**Date:** February 3, 2026  
**Project:** MECH0020 - Numerical Analysis of Tsunami Vortices on Ocean Surfaces  
**Institution:** University College London

---

## Table of Contents

1. [Research Summary](#research-summary)
2. [Current UI Assessment](#current-ui-assessment)
3. [Professional Interface Analysis](#professional-interface-analysis)
4. [Technology Stack Options](#technology-stack-options)
5. [Recommended Solution](#recommended-solution)
6. [Implementation Plan](#implementation-plan)
7. [Multi-Vortex IC Dispersion Fix](#multi-vortex-ic-dispersion-fix)
8. [LaTeX Rendering Integration](#latex-rendering-integration)

---

## 1. Research Summary

### Professional Simulation Software Researched

#### COMSOL Multiphysics
- **Interface Style:** Model Builder workflow (Geometry  Materials  Physics  Mesh  Solve  Results)
- **Key Features:**
  - Application Builder for custom simplified UIs
  - Model Manager for version control
  - Consistent interface across all physics domains
  - Rich professional visualization with LaTeX equations
  - Tabbed workflow panels
- **Design Patterns:**
  - Left panel: Model tree with hierarchical steps
  - Center: Large visualization area
  - Right: Context-sensitive property panels
  - Bottom: Messages and progress bars

#### ANSYS Fluent
- **Interface Style:** Single window, streamlined workflow
- **Key Features:**
  - User-friendly task-based workflows
  - Best-in-class physics visualization
  - AI Virtual Assistant integration (Engineering CoPilot)
  - Parallel processing capabilities
  - PyFluent API for automation
- **Design Patterns:**
  - Ribbon-style menus organized by function
  - Embedded 3D visualization
  - Property panels with validation
  - Real-time progress monitoring

#### ParaView
- **Interface Style:** Open-source post-processing visualization
- **Key Features:**
  - Web-based interface option (via Trame)
  - Pipeline-based workflow
  - In-situ visualization capabilities
  - Professional scientific colormaps
  - Multiple linked views
- **Design Patterns:**
  - Pipeline browser (data flow visualization)
  - 3D render view (main area)
  - Properties panel
  - Color mapping and legends

### Web-Based Framework Research

#### Streamlit
- **Type:** Python web app framework
- **Advantages:**
  - Pure Python (no HTML/CSS/JS knowledge needed)
  - Build data apps in minutes
  - Automatic UI updates with code changes
  - Compatible with Matplotlib, NumPy, Pandas
  - Easy deployment
- **MATLAB Integration:**
  - Can call MATLAB via MATLAB Engine for Python
  - Seamless data exchange
- **LaTeX Support:**
  - Native LaTeX rendering via -Force...-Force syntax
  - Matplotlib integration for scientific plots
- **Installation:** pip install streamlit

#### Qt/PySide6
- **Type:** Professional cross-platform GUI framework
- **Advantages:**
  - Industry-standard professional UIs
  - Rich widget library
  - Excellent performance
  - Native OS integration
  - Full control over UI design
- **MATLAB Integration:**
  - Seamless via MATLAB Engine for Python
  - Use py. prefix in MATLAB to call Python
  - Bidirectional data conversion
- **LaTeX Support:**
  - Full LaTeX via Matplotlib integration
  - QLabel with HTML subset for simple equations
- **Installation:** pip install pyside6

---

## 2. Current UI Assessment

### Existing Implementation: UIController.m

**Technology:** MATLAB App Designer (uifigure, uitab components)

**Strengths:**
-  Native MATLAB integration
-  No external dependencies
-  13-14pt fonts (recently improved)
-  Support for all 9 IC types
-  Tabbed organization
-  Embedded monitors

**Weaknesses:**
-  "Not clear and looks unprofessional" (user feedback)
-  Limited LaTeX support (TeX interpreter only, not full LaTeX)
-  Multi-vortex ICs show all vortices in same location
-  Less modern appearance compared to COMSOL/ANSYS
-  Limited customization options for advanced layouts
-  No 3D visualization capabilities
-  Difficult to create truly professional-looking interfaces

### User Requirements

1. **Professional Appearance:** Interface should look like COMSOL/ANSYS/ParaView
2. **LaTeX Mathematics:** All equations rendered in LaTeX format
3. **Multi-Vortex Dispersion:** IC preview should show vortices spatially dispersed
4. **Seamless MATLAB Integration:** If using external framework, must work seamlessly with MATLAB backend
5. **Clear and Intuitive:** Workflow should be obvious and organized

---

## 3. Professional Interface Analysis

### Common Design Patterns Across All Professional Tools

#### Workflow Organization
`
[Model Setup]  [Configuration]  [Execution]  [Visualization]  [Analysis]
`

All professional tools follow this linear workflow pattern.

#### Layout Structure
`

  Title Bar / Menu / Ribbon                                  

                                                           
  Tree/        Main Visualization             Properties   
  Nav          (Large Central Area)           Panel        
  Panel                                                    
                                                           

  Status Bar / Progress / Messages                           

`

#### Color Schemes
- **COMSOL:** Light gray backgrounds (#F0F0F0), blue accents
- **ANSYS:** Dark themes available, professional gray/blue palette
- **ParaView:** Dark theme default, customizable

#### Typography
- Sans-serif fonts (Arial, Helvetica, Segoe UI)
- Hierarchical sizes: 16-18pt titles, 12-14pt body, 10-12pt labels
- Bold for headers, regular for content

---

## 4. Technology Stack Options

### Option A: Enhanced MATLAB App Designer

**Approach:** Significantly redesign current UIController.m

**Pros:**
-  No external dependencies
-  Native MATLAB integration
-  All MATLAB users can run without setup
-  Direct access to all MATLAB functions

**Cons:**
-  Limited LaTeX support (TeX only)
-  Difficult to achieve truly professional appearance
-  Limited modern UI components
-  Cannot easily integrate 3D visualization libraries
-  Harder to create responsive layouts

**Verdict:**  Viable but limited in achieving professional appearance

---

### Option B: Python + Qt (PySide6) with MATLAB Backend

**Approach:** Create professional Qt-based UI in Python, call MATLAB engine for simulations

**Architecture:**
`

  PySide6 Professional UI (Python)  
  - LaTeX rendering (matplotlib)    
  - Modern widgets and layouts      
  - Real-time plot updates          

            
             MATLAB Engine API
             (bidirectional)
            

  MATLAB Simulation Backend         
  - run_simulation_with_method()    
  - extract_unified_metrics()       
  - All numerical methods           

`

**MATLAB-Python Integration Example:**
`matlab
% From MATLAB: Call Python
py.list({'This','is a','list'})
py.numpy.array([1, 2, 3])
pyrun("x = 5 + 3; print(x)")
`

`python
# From Python: Call MATLAB
import matlab.engine
eng = matlab.engine.start_matlab()
results = eng.run_simulation_with_method(params, nargout=1)
`

**Pros:**
-  Professional industry-standard UI framework
-  Full LaTeX support via Matplotlib
-  Complete customization control
-  Modern widgets (tabs, panels, splitters)
-  Easy integration of 3D visualization (VTK, PyVista)
-  Cross-platform (Windows, Mac, Linux)
-  Can package as standalone executable
-  Seamless MATLAB integration confirmed

**Cons:**
-  Requires Python installation + PySide6
-  Requires MATLAB Engine for Python setup
-  Additional learning curve for Python/Qt
-  Two languages to maintain

**Setup Requirements:**
`ash
pip install pyside6
pip install matplotlib numpy
cd "matlabroot/extern/engines/python"
python setup.py install
`

**Verdict:**  **Best option for professional appearance and full feature set**

---

### Option C: Streamlit Web App with MATLAB Backend

**Approach:** Create web-based dashboard using Streamlit, connect to MATLAB

**Architecture:**
`

  Streamlit Web Interface           
  (Browser: localhost:8501)         
  - st.latex() for equations        
  - st.pyplot() for Matplotlib      
  - Auto-refreshing UI              

            
             MATLAB Engine API
            

  MATLAB Simulation Backend         

`

**Streamlit Example:**
`python
import streamlit as st
import matlab.engine

st.title("Tsunami Vortex Simulation")

# LaTeX equation
st.latex(r"\frac{\partial \omega}{\partial t} + u \frac{\partial \omega}{\partial x} = 0")

# Run simulation
if st.button("Run Simulation"):
    eng = matlab.engine.start_matlab()
    results = eng.run_simulation_with_method(params)
    st.pyplot(results['figure'])
`

**Pros:**
-  Very quick development (build UI in hours)
-  Native LaTeX support
-  Auto-refreshing interface
-  Easy deployment (can share via web)
-  Modern, clean appearance
-  Great for dashboards and monitoring

**Cons:**
-  Less control over layout compared to Qt
-  Requires browser (not native app)
-  Streamlit paradigm: script reruns on interaction
-  Limited for complex interactive 3D visualization
-  Requires running Streamlit server

**Setup:**
`ash
pip install streamlit
streamlit run app.py
`

**Verdict:**  **Excellent for rapid prototyping and web-accessible dashboards**

---

### Option D: MATLAB + Custom LaTeX Rendering

**Approach:** Keep MATLAB App Designer but add external LaTeX rendering

**How It Works:**
- Generate LaTeX equations as images using external tool (e.g., latex2png, MathJax Node)
- Display images in uiimage components
- For plots, use 	ext() with 'interpreter','latex' (requires LaTeX installation)

**Pros:**
-  Stays within MATLAB ecosystem
-  Minimal external dependencies

**Cons:**
-  Requires LaTeX installation on system
-  Complex pipeline (generate  convert  display)
-  Slow compared to native LaTeX rendering
-  Still doesn't solve overall "unprofessional" appearance issue

**Verdict:**  **Not recommended** - too complex for limited improvement

---

## 5. Recommended Solution

###  Primary Recommendation: Python + PySide6 with MATLAB Backend

**Rationale:**
1. Achieves professional appearance matching COMSOL/ANSYS
2. Full LaTeX rendering capability
3. Seamless MATLAB integration confirmed (bidirectional)
4. Industry-standard framework used by commercial software
5. Complete control over UI design
6. Future-proof (can add 3D visualization, web export, etc.)

**Fallback/Alternative:** Streamlit for rapid development if timeline is critical

---

### Implementation Architecture

#### Technology Stack

**Frontend (UI):**
- **Framework:** PySide6 (Qt6 for Python)
- **Plotting:** Matplotlib (embedded in Qt)
- **LaTeX:** Matplotlib's LaTeX renderer
- **3D Viz (optional):** PyVista or VTK integration

**Backend (Computation):**
- **Engine:** MATLAB
- **Integration:** MATLAB Engine for Python
- **Data Exchange:** Automatic conversion (NumPy  MATLAB arrays)

**Connectivity:**
`python
# Python UI code
import matlab.engine
from PySide6.QtWidgets import *
import matplotlib.pyplot as plt

class TsunamiSimulationUI(QMainWindow):
    def __init__(self):
        super().__init__()
        self.matlab_eng = matlab.engine.start_matlab()
        self.setup_ui()
    
    def run_simulation(self):
        # Get parameters from UI
        params = self.get_parameters()
        
        # Call MATLAB
        results = self.matlab_eng.run_simulation_with_method(
            params, nargout=2
        )
        
        # Display results in UI
        self.display_results(results)
`

#### UI Layout Design

**Main Window Structure:**
`

  Tsunami Vortex Simulation - Professional Interface                
  File  Edit  View  Simulation  Analysis  Help                      

                                                                  
  Workflow        Visualization Area                 Parameters   
  Navigator       (MatplotlibWidget)                 Panel        
                                                                  
   Setup        [3D/2D plot with LaTeX labels]     Method: [] 
    Method                                                      
    IC                                             IC Type: []
    Domain                                                      
                                                     Grid: [   ] 
   Run                                                           
    Solve                                          Time: [   ] 
    Monitor                                                     
                                                     [Run Button]
   Results                                                      
    Plots                                                       
    Metrics                                                     
    Export                                                      

   Ready    Grid: 128x128    Method: FD    Progress:  50% 

`

**Key Components:**

1. **Left Panel: Workflow Navigator**
   - Hierarchical tree view
   - Icons for each step
   - Progress indicators

2. **Center Panel: Visualization**
   - Large area for plots
   - Toolbar with zoom/pan
   - LaTeX-rendered axis labels
   - Professional colormaps

3. **Right Panel: Parameters**
   - Context-sensitive controls
   - Grouped by category
   - Validation indicators
   - Tooltips with equations (LaTeX)

4. **Status Bar:**
   - Current state
   - Progress bars
   - Key metrics display

---

### LaTeX Rendering Implementation

**Method 1: Matplotlib rc Params (Preferred)**
`python
import matplotlib
matplotlib.rcParams['text.usetex'] = True
matplotlib.rcParams['font.family'] = 'serif'

# Plot with LaTeX
fig, ax = plt.subplots()
ax.plot(x, y)
ax.set_xlabel(r'$ [m]')
ax.set_ylabel(r'$\omega(x,t)$ [sNew-Item{-1}$]')
ax.set_title(r'$\frac{\partial \omega}{\partial t} + u\cdot\nabla\omega = 0$')
`

**Method 2: MathText (No LaTeX installation required)**
`python
# Uses Matplotlib's built-in LaTeX-like rendering
ax.set_xlabel(r'$\vorticity \quad \omega$', fontsize=14)
ax.text(0.5, 0.5, r' = \frac{1}{2}\int u^2 + v^2 \, dx dy$')
`

**Method 3: Qt Labels with HTML**
`python
from PySide6.QtWidgets import QLabel

# For simple equations
label = QLabel()
label.setText("<i>ω</i> = <i>v</i>/<i>x</i> - <i>u</i>/<i>y</i>")
`

---

### Multi-Vortex IC Dispersion Solution

**Problem:** All vortices currently positioned at same location (0,0)

**Solution:** Spatial dispersion pattern

**Implementation Locations:**
1. IC generation functions (Scripts/Initial_Conditions/ic_*.m)
2. UIController preview generation

**Dispersion Patterns:**

**Pattern 1: Circular Arrangement**
`matlab
function [x0_list, y0_list] = disperse_vortices_circular(n_vortices, radius, Lx, Ly)
    % Arrange n vortices in a circle
    theta = linspace(0, 2*pi, n_vortices+1);
    theta(end) = [];  % Remove duplicate
    
    x0_list = radius * cos(theta);
    y0_list = radius * sin(theta);
end
`

**Pattern 2: Grid Arrangement**
`matlab
function [x0_list, y0_list] = disperse_vortices_grid(n_vortices, Lx, Ly)
    % Arrange vortices in a grid pattern
    n_rows = floor(sqrt(n_vortices));
    n_cols = ceil(n_vortices / n_rows);
    
    spacing_x = Lx / (n_cols + 1);
    spacing_y = Ly / (n_rows + 1);
    
    [X, Y] = meshgrid(1:n_cols, 1:n_rows);
    x0_list = (X(:) * spacing_x - Lx/2)';
    y0_list = (Y(:) * spacing_y - Ly/2)';
    
    % Trim to exact number
    x0_list = x0_list(1:n_vortices);
    y0_list = y0_list(1:n_vortices);
end
`

**Pattern 3: Random with Minimum Separation**
`matlab
function [x0_list, y0_list] = disperse_vortices_random(n_vortices, Lx, Ly, min_dist)
    % Randomly place vortices with minimum separation
    x0_list = [];
    y0_list = [];
    
    max_attempts = 1000;
    for i = 1:n_vortices
        placed = false;
        for attempt = 1:max_attempts
            x_new = (rand - 0.5) * Lx * 0.8;
            y_new = (rand - 0.5) * Ly * 0.8;
            
            % Check minimum distance to existing vortices
            if isempty(x0_list)
                valid = true;
            else
                distances = sqrt((x0_list - x_new).^2 + (y0_list - y_new).^2);
                valid = all(distances >= min_dist);
            end
            
            if valid
                x0_list(end+1) = x_new;
                y0_list(end+1) = y_new;
                placed = true;
                break;
            end
        end
        
        if ~placed
            warning('Could not place vortex %d with minimum separation', i);
        end
    end
end
`

**Integration with IC Functions:**

Example for ic_lamb_oseen.m:
`matlab
% Before (single vortex at x0, y0):
omega = Gamma/(pi*rc^2) * exp(-((x-x0).^2 + (y-y0).^2)/rc^2);

% After (multiple vortices):
if isfield(Parameters, 'n_vortices') && Parameters.n_vortices > 1
    % Disperse vortex centers
    [x0_list, y0_list] = disperse_vortices_grid(Parameters.n_vortices, Lx, Ly);
    
    % Superpose vortices
    omega = zeros(size(x));
    for i = 1:Parameters.n_vortices
        omega = omega + Gamma/(pi*rc^2) * ...
            exp(-((x-x0_list(i)).^2 + (y-y0_list(i)).^2)/rc^2);
    end
else
    % Single vortex (current behavior)
    omega = Gamma/(pi*rc^2) * exp(-((x-x0).^2 + (y-y0).^2)/rc^2);
end
`

---

## 6. Implementation Plan

### Phase 1: Environment Setup (1 week)

**Week 1: Python + MATLAB Integration**

**Task Checklist:**
- [ ] Install Python 3.9+ (if not already installed)
- [ ] Install PySide6: pip install pyside6
- [ ] Install scientific stack: pip install matplotlib numpy scipy
- [ ] Install MATLAB Engine for Python:
  `ash
  cd "C:\Program Files\MATLAB\R2024b\extern\engines\python"
  python setup.py install
  `
- [ ] Test MATLAB-Python connection:
  `python
  import matlab.engine
  eng = matlab.engine.start_matlab()
  print(eng.sqrt(4.0))  # Should print 2.0
  `
- [ ] Create test Qt window:
  `python
  from PySide6.QtWidgets import QApplication, QMainWindow
  app = QApplication([])
  window = QMainWindow()
  window.setWindowTitle("Test")
  window.show()
  app.exec()
  `

---

### Phase 2: UI Architecture Design (1 week)

**Week 2: Detailed UI Design**

- [ ] Create mockup of main window layout
- [ ] Design color scheme (match COMSOL palette)
- [ ] Define all UI components and their interactions
- [ ] Plan state management (parameters, results storage)
- [ ] Design data flow between UI and MATLAB
- [ ] Create UML diagrams for class structure

**Deliverables:**
- UI mockup (PNG/PDF)
- Component hierarchy document
- API specification (Python  MATLAB)

---

### Phase 3: Core UI Implementation (2-3 weeks)

**Week 3-4: Build Main Interface**

**Structure:**
`
tsunami_ui/
 main.py                 # Entry point
 ui/
    main_window.py      # Main window class
    panels/
       workflow_navigator.py
       parameters_panel.py
       visualization_panel.py
    dialogs/
        ic_config_dialog.py
        method_config_dialog.py
 matlab_interface/
    engine_manager.py   # MATLAB engine wrapper
    data_converter.py   # Data type conversions
 utils/
     latex_renderer.py   # LaTeX helper functions
     validators.py       # Parameter validation
`

**Task Checklist:**
- [ ] Create main window with menu bar
- [ ] Implement left panel (workflow navigator)
- [ ] Implement right panel (parameters)
- [ ] Implement center panel (Matplotlib canvas)
- [ ] Add status bar with progress indicators
- [ ] Connect all signals/slots

---

### Phase 4: MATLAB Integration (1 week)

**Week 5: Backend Connection**

- [ ] Create MATLAB engine manager class
- [ ] Implement parameter conversion (Python dict  MATLAB struct)
- [ ] Implement result retrieval (MATLAB  Python)
- [ ] Test with run_simulation_with_method()
- [ ] Test with extract_unified_metrics()
- [ ] Handle MATLAB errors gracefully in UI

**Example Code:**
`python
# matlab_interface/engine_manager.py
import matlab.engine

class MATLABEngineManager:
    def __init__(self):
        print("Starting MATLAB...")
        self.eng = matlab.engine.start_matlab()
        print("MATLAB ready")
        
        # Add paths
        self.eng.addpath('Scripts/Methods', nargout=0)
        self.eng.addpath('Scripts/Initial_Conditions', nargout=0)
    
    def run_simulation(self, params_dict):
        # Convert Python dict to MATLAB struct
        matlab_params = self.eng.struct()
        for key, value in params_dict.items():
            self.eng.setfield(matlab_params, key, value)
        
        # Run simulation
        fig_handle, analysis = self.eng.run_simulation_with_method(
            matlab_params, nargout=2
        )
        
        return fig_handle, analysis
    
    def extract_metrics(self, analysis_struct):
        metrics = self.eng.extract_unified_metrics(
            analysis_struct, nargout=1
        )
        return metrics
    
    def close(self):
        self.eng.quit()
`

---

### Phase 5: LaTeX Integration (1 week)

**Week 6: Mathematical Notation**

- [ ] Configure Matplotlib for LaTeX rendering
- [ ] Create LaTeX templates for all IC equations
- [ ] Add LaTeX to axis labels
- [ ] Add LaTeX to legends
- [ ] Create tooltip system with LaTeX equations
- [ ] Test on system (verify LaTeX installation or use MathText)

**IC Equation Templates:**
`python
IC_EQUATIONS = {
    'lamb_oseen': r'$\omega = \frac{\Gamma}{\pi r_c^2} e^{-r^2/r_c^2}$',
    'rankine': r'$\omega = \begin{cases} \frac{\Gamma}{\pi r_c^2} & r < r_c \\ 0 & r \geq r_c \end{cases}$',
    'taylor_green': r' = -\cos(kx)\sin(ky), \quad v = \sin(kx)\cos(ky)$',
    'lamb_dipole': r'$\psi = -U_0 R \frac{J_1(k_1 r)}{J_1(k_1 R)} \sin\theta$',
    # ... etc for all 9 IC types
}
`

**Display in UI:**
`python
# In parameters panel
eq_label = QLabel()
eq_pixmap = self.render_latex_to_pixmap(IC_EQUATIONS[ic_type])
eq_label.setPixmap(eq_pixmap)
`

---

### Phase 6: Multi-Vortex Dispersion (1 week)

**Week 7: IC Spatial Distribution**

- [ ] Add disperse_vortices_circular() function to MATLAB
- [ ] Add disperse_vortices_grid() function
- [ ] Add disperse_vortices_random() function
- [ ] Update all IC functions to support multi-vortex
- [ ] Add UI control for dispersion pattern selection
- [ ] Test preview with multiple vortices
- [ ] Verify simulation accuracy with dispersed vortices

**UI Addition:**
`python
# In IC configuration panel
n_vortices_spin = QSpinBox()
n_vortices_spin.setRange(1, 10)

dispersion_combo = QComboBox()
dispersion_combo.addItems(['None', 'Circular', 'Grid', 'Random'])

# Show dispersion pattern preview
preview_canvas = FigureCanvas(Figure())
self.update_ic_preview()
`

---

### Phase 7: Testing & Refinement (1-2 weeks)

**Week 8-9: Quality Assurance**

- [ ] Test all numerical methods (FD, FV, Spectral, Bathymetry)
- [ ] Test all 9 IC types
- [ ] Test multi-vortex scenarios
- [ ] Verify LaTeX rendering on all components
- [ ] Performance testing (large grids)
- [ ] Error handling (invalid parameters, MATLAB crashes)
- [ ] User testing (get feedback from colleagues)
- [ ] Bug fixes

---

### Phase 8: Documentation (1 week)

**Week 10: User Guide**

- [ ] Write UI user manual
- [ ] Create video tutorial (screen recording)
- [ ] Document MATLAB-Python integration
- [ ] Update project README
- [ ] Create quick-start guide
- [ ] Add inline help/tooltips to UI

---

## 7. Quick Win: Immediate Improvements to Current UI

**If full redesign timeline is too long, make these improvements to UIController.m immediately:**

### Fix 1: Multi-Vortex IC Dispersion (Priority 1)

**File:** Scripts/Initial_Conditions/ic_lamb_oseen.m (and all others)

**Before:**
`matlab
% All vortices at (x0, y0) = (0, 0)
omega = Gamma/(pi*rc^2) * exp(-((x-x0).^2 + (y-y0).^2)/rc^2);
`

**After:**
`matlab
% At top of function, add helper
function [x0_list, y0_list] = get_vortex_positions(n_vortices, Lx, Ly)
    if n_vortices == 1
        x0_list = 0;
        y0_list = 0;
    else
        % Grid pattern
        n_cols = ceil(sqrt(n_vortices));
        n_rows = ceil(n_vortices / n_cols);
        spacing_x = Lx / (n_cols + 1);
        spacing_y = Ly / (n_rows + 1);
        
        k = 1;
        x0_list = zeros(1, n_vortices);
        y0_list = zeros(1, n_vortices);
        for i = 1:n_rows
            for j = 1:n_cols
                if k <= n_vortices
                    x0_list(k) = j * spacing_x - Lx/2;
                    y0_list(k) = i * spacing_y - Ly/2;
                    k = k + 1;
                end
            end
        end
    end
end

% In main IC generation
n_vortices = Parameters.n_vortices;
[x0_list, y0_list] = get_vortex_positions(n_vortices, Parameters.Lx, Parameters.Ly);

omega = zeros(size(x));
for i = 1:n_vortices
    omega = omega + Gamma/(pi*rc^2) * ...
        exp(-((x-x0_list(i)).^2 + (y-y0_list(i)).^2)/rc^2);
end
`

**Apply to all IC files:**
- ic_lamb_oseen.m
- ic_rankine.m
- ic_lamb_dipole.m
- ic_taylor_green.m
- ic_elliptical_vortex.m
- ic_random_turbulence.m

---

### Fix 2: Improved LaTeX-Style Notation

**File:** UIController.m

**Current:** Using ^2, omega, etc.

**Improved:** Use Unicode characters for better appearance

`matlab
% In IC equation display functions

% Before:
eq_text = 'omega = (Gamma/pi*rc^2) * exp(-r^2/rc^2)';

% After:
eq_text = 'ω = (Γ/πrᶜ)  exp(-r/rᶜ)';
% Or HTML formatting:
eq_html = '<html><i>ω</i> = (<i>Γ</i>/π<i>r</i><sub>c</sub><sup>2</sup>)  exp(-<i>r</i><sup>2</sup>/<i>r</i><sub>c</sub><sup>2</sup>)</html>';
`

**Unicode Greek letters:**
- ω (U+03C9) for omega
- Γ (U+0393) for Gamma
- ν (U+03BD) for nu
- θ (U+03B8) for theta

---

### Fix 3: Professional Color Scheme

**Current:** Default gray

**New:** COMSOL-inspired palette

`matlab
% In UIController constructor
app.fig.Color = [0.94 0.94 0.96];  % Light gray-blue

% Panel backgrounds
panel_color = [0.98 0.98 1.0];  % Very light blue-white

% Accent color (for buttons, highlights)
accent_color = [0.2 0.4 0.8];  % Professional blue

% Status indicators
success_color = [0.2 0.7 0.3];  % Green
warning_color = [0.9 0.6 0.1];  % Orange
error_color = [0.8 0.2 0.2];    % Red
`

---

### Fix 4: Larger Fonts

**Already done, but ensure consistency:**

`matlab
% Title labels: 16pt bold
uilabel(..., 'FontSize', 16, 'FontWeight', 'bold');

% Section headers: 14pt bold
uilabel(..., 'FontSize', 14, 'FontWeight', 'bold');

% Body text: 13pt regular
uilabel(..., 'FontSize', 13);

% Small labels: 11pt
uilabel(..., 'FontSize', 11);
`

---

## 8. Timeline Summary

### Quick Wins (1 week)
-  Multi-vortex IC dispersion fix
-  Improved Unicode notation
-  Better color scheme
- Result: **Current UI improved but still limited**

### Full Python + Qt Implementation (10-12 weeks)
- Week 1: Environment setup
- Week 2: UI design
- Weeks 3-4: Core UI implementation
- Week 5: MATLAB integration
- Week 6: LaTeX rendering
- Week 7: Multi-vortex dispersion
- Weeks 8-9: Testing
- Week 10: Documentation
- Result: **Professional-grade interface matching COMSOL/ANSYS**

### Streamlit Alternative (4-6 weeks)
- Week 1: Setup + basic layout
- Week 2: MATLAB integration
- Week 3: All features + LaTeX
- Week 4: Testing + documentation
- Result: **Modern web-based interface, good appearance but less control**

---

## 9. Recommendation

### For Best Results: Pursue Qt Solution

**Immediate Action (This Week):**
1.  Fix multi-vortex IC dispersion in all IC functions
2.  Improve current UIController color scheme and notation
3. Install Python + PySide6 + MATLAB Engine
4. Create simple test: Qt window calling MATLAB function

**Next Steps (Following Weeks):**
1. Design detailed UI mockup
2. Begin Qt implementation following architecture above
3. Parallel development: improve current UI while building new one
4. Switch to new UI when ready

**Fallback Plan:**
- If Qt timeline too long, use Streamlit for faster deployment
- Keep improved MATLAB UI as option for users without Python

---

## 10. Code Examples

### Complete Minimal Qt + MATLAB Example

**main.py:**
`python
import sys
from PySide6.QtWidgets import QApplication
from ui.main_window import TsunamiSimulationWindow

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = TsunamiSimulationWindow()
    window.show()
    sys.exit(app.exec())
`

**ui/main_window.py:**
`python
from PySide6.QtWidgets import (QMainWindow, QWidget, QVBoxLayout, 
                               QHBoxLayout, QPushButton, QLabel,
                               QComboBox, QSpinBox)
from PySide6.QtCore import Qt
from matlab_interface.engine_manager import MATLABEngineManager
import matplotlib
matplotlib.use('Qt5Agg')
from matplotlib.backends.backend_qt5agg import FigureCanvasQTAgg
from matplotlib.figure import Figure

class TsunamiSimulationWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Tsunami Vortex Simulation - Professional Interface")
        self.setGeometry(100, 100, 1600, 900)
        
        # Initialize MATLAB engine
        self.matlab_eng = MATLABEngineManager()
        
        # Setup UI
        self.setup_ui()
        
    def setup_ui(self):
        # Central widget
        central = QWidget()
        self.setCentralWidget(central)
        main_layout = QHBoxLayout(central)
        
        # Left panel: Controls
        left_panel = self.create_left_panel()
        main_layout.addWidget(left_panel, 1)
        
        # Center panel: Visualization
        self.canvas = FigureCanvasQTAgg(Figure(figsize=(8, 6)))
        main_layout.addWidget(self.canvas, 3)
        
        # Right panel: Parameters
        right_panel = self.create_right_panel()
        main_layout.addWidget(right_panel, 1)
    
    def create_left_panel(self):
        widget = QWidget()
        layout = QVBoxLayout(widget)
        
        # Title
        title = QLabel("Workflow")
        title.setStyleSheet("font-size: 16pt; font-weight: bold;")
        layout.addWidget(title)
        
        # Method selection
        layout.addWidget(QLabel("Numerical Method:"))
        self.method_combo = QComboBox()
        self.method_combo.addItems(['Finite Difference', 'Finite Volume', 
                                      'Spectral', 'Variable Bathymetry'])
        layout.addWidget(self.method_combo)
        
        layout.addStretch()
        return widget
    
    def create_right_panel(self):
        widget = QWidget()
        layout = QVBoxLayout(widget)
        
        # Title
        title = QLabel("Parameters")
        title.setStyleSheet("font-size: 16pt; font-weight: bold;")
        layout.addWidget(title)
        
        # IC selection
        layout.addWidget(QLabel("Initial Condition:"))
        self.ic_combo = QComboBox()
        self.ic_combo.addItems(['Lamb-Oseen', 'Rankine', 'Taylor-Green',
                                 'Lamb Dipole', 'Elliptical', 'Random'])
        self.ic_combo.currentTextChanged.connect(self.update_ic_equation)
        layout.addWidget(self.ic_combo)
        
        # IC equation display (LaTeX)
        self.ic_equation = QLabel()
        self.ic_equation.setAlignment(Qt.AlignCenter)
        layout.addWidget(self.ic_equation)
        self.update_ic_equation()
        
        # Grid size
        layout.addWidget(QLabel("Grid Size (N):"))
        self.grid_spin = QSpinBox()
        self.grid_spin.setRange(32, 512)
        self.grid_spin.setValue(128)
        self.grid_spin.setSingleStep(32)
        layout.addWidget(self.grid_spin)
        
        # Number of vortices
        layout.addWidget(QLabel("Number of Vortices:"))
        self.n_vortices_spin = QSpinBox()
        self.n_vortices_spin.setRange(1, 10)
        self.n_vortices_spin.setValue(1)
        layout.addWidget(self.n_vortices_spin)
        
        # Run button
        self.run_button = QPushButton(" Run Simulation")
        self.run_button.setStyleSheet("""
            QPushButton {
                background-color: #2060C0;
                color: white;
                font-size: 14pt;
                font-weight: bold;
                padding: 10px;
                border-radius: 5px;
            }
            QPushButton:hover {
                background-color: #3070D0;
            }
        """)
        self.run_button.clicked.connect(self.run_simulation)
        layout.addWidget(self.run_button)
        
        layout.addStretch()
        return widget
    
    def update_ic_equation(self):
        # LaTeX equations for each IC type
        equations = {
            'Lamb-Oseen': r'$\omega = \frac{\Gamma}{\pi r_c^2} e^{-r^2/r_c^2}$',
            'Rankine': r'$\omega = \begin{cases} \frac{\Gamma}{\pi r_c^2} & r < r_c \\ 0 & r \geq r_c \end{cases}$',
            'Taylor-Green': r' = -\cos(kx)\sin(ky)$,  = \sin(kx)\cos(ky)$',
            # ... add all others
        }
        
        ic_type = self.ic_combo.currentText()
        eq = equations.get(ic_type, '')
        
        # Render LaTeX to image and display
        # (Implementation: use matplotlib to render LaTeX, convert to QPixmap)
        self.ic_equation.setText(f"Equation: {eq}")  # Simplified for now
    
    def run_simulation(self):
        # Get parameters from UI
        params = {
            'Method': self.method_combo.currentText(),
            'IC_type': self.ic_combo.currentText(),
            'N': self.grid_spin.value(),
            'n_vortices': self.n_vortices_spin.value(),
            'Lx': 10.0,
            'Ly': 10.0,
            'T': 5.0,
            'dt': 0.01,
            # ... other parameters
        }
        
        # Run simulation via MATLAB
        self.run_button.setEnabled(False)
        self.run_button.setText(" Running...")
        
        try:
            fig_handle, analysis = self.matlab_eng.run_simulation(params)
            
            # Display results
            # (Get data from MATLAB and plot in canvas)
            self.display_results(analysis)
            
            self.run_button.setText(" Complete")
        except Exception as e:
            self.run_button.setText(" Error")
            print(f"Error: {e}")
        finally:
            self.run_button.setEnabled(True)
    
    def display_results(self, analysis):
        # Clear canvas
        self.canvas.figure.clear()
        
        # Create plot
        ax = self.canvas.figure.add_subplot(111)
        
        # Get data from MATLAB analysis struct
        # (Simplified - actual implementation would extract data properly)
        x = [0, 1, 2, 3, 4]
        y = [0, 1, 4, 9, 16]
        
        ax.plot(x, y)
        ax.set_xlabel(r'$ [m]', fontsize=14)
        ax.set_ylabel(r'$\omega$ [sNew-Item{-1}$]', fontsize=14)
        ax.set_title(r'Vorticity: $\omega(x,t)$', fontsize=16)
        ax.grid(True, alpha=0.3)
        
        self.canvas.draw()
    
    def closeEvent(self, event):
        # Clean up MATLAB engine
        self.matlab_eng.close()
        event.accept()
`

---

## Conclusion

This comprehensive research demonstrates that:

1. **Professional simulation interfaces follow common design patterns** (COMSOL, ANSYS, ParaView)
2. **Python + Qt provides the best path to professional UI** with full MATLAB integration
3. **Streamlit offers rapid development alternative** for web-based dashboards
4. **Quick wins available immediately** by fixing multi-vortex dispersion and improving notation
5. **Full LaTeX rendering is achievable** with Python frameworks but limited in MATLAB

**Recommended Path Forward:**
1.  Implement quick wins this week (multi-vortex fix, better colors/fonts)
2. Set up Python + Qt environment
3. Build professional Qt interface over 10-12 weeks
4. Maintain improved MATLAB UI as fallback option

**This will result in a simulation interface that rivals commercial CFD software in appearance and usability.**

---

**Document Version:** 1.0  
**Last Updated:** February 3, 2026  
**Next Review:** Start of Phase 1 implementation

