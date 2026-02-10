# Experimentation Mode & Advanced Visualization Guide

**Version:** 4.0  
**Date:** January 27, 2026  
**Status:** Ready for Production

---

## Overview

This document describes three major enhancements to Analysis.m:

1. **New Experimentation Mode** - Test various initial conditions (multiple vortices, non-uniform boundaries)
2. **Advanced Visualization Methods** - Configurable contour and vector field plotting
3. **ML Framework Planning** - Guidance for vorticity neutralization research

---

## Part 1: Convergence Figure Saving - VERIFIED ✅

### Status
✅ **CONFIRMED WORKING** - Figures ARE being saved during convergence study

### Evidence
The function `save_convergence_figures` is called at multiple points during convergence:
- **Phase 1** (initial_pair): Lines 585, 608
- **Phase 2** (adaptive_jump): Line 659
- **Phase 3** (bracketing): Line 717
- **Phase 4** (binary_search): Line 1638

### Directory Structure
```
Figures/Finite Difference/CONVERGENCE/
└── Convergence/
    ├── Phase_Coarse/
    ├── Phase_Bracketing/
    ├── Phase_BinarySearch/
    └── Phase_FinalValidation/
```

Each phase saves timestamped subdirectories:
```
Phase_Coarse/
└── 20260127_143522_N0064_Nx=64_Ny=64/
    ├── conv_coarse_iter0001_N0064_Evolution.png
    ├── conv_coarse_iter0001_N0064_Contour.png
    └── conv_coarse_iter0001_N0064_Vectorised.png
```

### Configuration
Enable/disable convergence figure saving:
```matlab
convergence.save_iteration_figures = true;  % Line ~155
```

---

## Part 2: Advanced Visualization Methods

### 2.1 Contour Plot Methods

Two methods are now supported for streamfunction contours:

#### Method 1: Line Contours (Traditional)
```matlab
visualization.contour_method = "contour";
visualization.contour_levels = 20;
```
**Output:** Black line contours overlaid on vorticity field  
**Use Case:** Traditional scientific visualization, cleaner paper figures  
**Performance:** Fast, minimal memory

#### Method 2: Filled Contours (New)
```matlab
visualization.contour_method = "contourf";
visualization.contour_levels = 25;
```
**Output:** Colored filled contour regions overlaid on vorticity field  
**Use Case:** Modern visualization, publication quality, better visual impact  
**Performance:** Slightly slower, better visual distinction

### 2.2 Vector Field Visualization Methods

Two methods for velocity field display:

#### Method 1: Quiver Arrows (Default)
```matlab
visualization.vector_method = "quiver";
visualization.vector_subsampling = 4;      % Every 4th grid point
visualization.vector_scale = 1.0;          % Auto-scale (0 disables scaling)
```
**Output:** Arrow glyphs showing velocity direction and magnitude  
**Use Case:** Clear flow direction identification, traditional approach  
**Subsampling:** Reduces clutter (stride=4 means every 4th point)  
**Scale:** Auto=1.0, increase >1 for longer arrows, decrease <1 for shorter

#### Method 2: Streamlines (New)
```matlab
visualization.vector_method = "streamlines";
visualization.vector_subsampling = 4;      % Grid density
```
**Output:** Flow-following streamlines overlaid on speed field  
**Use Case:** Global flow pattern visualization, vortex center identification  
**Better For:** Identifying vortex cores and circulation patterns

### 2.3 Configuration Examples

**Example 1: Publication-Quality Figures**
```matlab
visualization.contour_method = "contourf";
visualization.contour_levels = 30;
visualization.vector_method = "streamlines";
visualization.vector_subsampling = 6;
visualization.colormap = "turbo";
figures.dpi = 300;
```

**Example 2: Research Analysis (fast iteration)**
```matlab
visualization.contour_method = "contour";
visualization.contour_levels = 15;
visualization.vector_method = "quiver";
visualization.vector_subsampling = 3;
visualization.colormap = "jet";
figures.dpi = 150;
```

**Example 3: Vector field focus**
```matlab
visualization.vector_method = "streamlines";
visualization.vector_subsampling = 8;      % Sparse grid
visualization.vector_scale = 1.5;          % Emphasize magnitude
```

### Implementation Details

The visualization settings are passed from Analysis.m → Finite_Difference_Analysis.m:

```matlab
% In Analysis.m
Parameters.visualization = visualization;

% In Finite_Difference_Analysis.m (Lines 214-278)
contour_method = Parameters.visualization.contour_method;
vector_method = Parameters.visualization.vector_method;
vector_stride = Parameters.visualization.vector_subsampling;
vector_scale = Parameters.visualization.vector_scale;
```

---

## Part 3: Experimentation Mode

### Overview

New run mode for testing different initial conditions and vortex configurations:

```matlab
run_mode = "experimentation";
experimentation.test_case = "double_vortex";
```

### Available Test Cases

#### 1. Double Vortex (Counter-Rotating)
```matlab
experimentation.test_case = "double_vortex";
```
- **Description:** Two counter-rotating vortices
- **Initial Condition:** Gaussian blobs at opposite y-positions
- **Parameters:** [Gamma1, R1, x1, y1, Gamma2, x2]
- **Typical Behavior:** Self-induced advection, circulation preservation
- **Use Case:** Basic vortex dynamics validation

**Example Configuration:**
```matlab
experimentation.test_case = "double_vortex";
% Internal: ic_coeff = [1.0, 2.0, 3.0, 7.0, -1.5, 2.5, ...]
% Two Gaussian vortices: one positive at (3.0, 7.0), one negative at (6.5, 2.5)
```

#### 2. Three Vortex System
```matlab
experimentation.test_case = "three_vortex";
```
- **Description:** Three vortices in various configurations
- **Parameters:** [G1,R1,x1,y1, G2,R2,x2,y2, G3,x3,y3]
- **Typical Behavior:** Complex interactions, instability potential
- **Use Case:** Multi-body dynamics, cascade instability
- **Research Value:** Models atmospheric phenomena

#### 3. Non-Uniform Boundary Condition
```matlab
experimentation.test_case = "non_uniform_boundary";
```
- **Description:** Stretched Gaussian with non-uniform domain stretching
- **Initial Condition:** Gaussian IC with variable stretching in x and y
- **Parameters:** [x_coeff, y_coeff] for stretching factors
- **Typical Behavior:** Anisotropic diffusion effects
- **Use Case:** Domain aspect ratio sensitivity analysis

**Example:**
```matlab
% Isotropic (default)
experimentation.test_case = "non_uniform_boundary";
% ic_coeff = [1.5, 1.5]  -> Equal stretching in x,y

% Anisotropic stretching
% ic_coeff = [1.0, 3.0]  -> y-stretched (elongated in y)
% ic_coeff = [3.0, 1.0]  -> x-stretched (elongated in x)
```

#### 4. Gaussian Vortex Merger
```matlab
experimentation.test_case = "gaussian_merger";
```
- **Description:** Single Gaussian blob (tests diffusion)
- **Initial Condition:** Smooth Gaussian at domain center
- **Parameters:** [Circulation, Radius, x_0, y_0]
- **Typical Behavior:** Viscous decay, profile broadening
- **Use Case:** Diffusion validation, energy dissipation study

#### 5. Counter-Rotating Pair (Strong Interaction)
```matlab
experimentation.test_case = "counter_rotating";
```
- **Description:** Intense counter-rotating pair configuration
- **Initial Condition:** Two Gaussian blobs with strong circulation
- **Parameters:** [G1,R1,x1,y1, G2,R2,x2,y2]
- **Typical Behavior:** Rapid advection, potential vortex fusion
- **Use Case:** High-interaction regime testing

### Running Experimentation Mode

**Step 1: Select test case**
```matlab
% Edit Analysis.m, line ~98
run_mode = "experimentation";

% Line ~167
experimentation.test_case = "double_vortex";  % or other cases
```

**Step 2: Configure simulation parameters**
```matlab
Nx = 256;                    % Grid resolution
Ny = 256;
nu = 1e-6;                   % Viscosity
dt = 0.01;                   % Timestep
Tfinal = 2.0;                % Final time
```

**Step 3: Run Analysis.m**
```matlab
% MATLAB command window
Analysis
```

**Step 4: View results**
```
Figures/Finite Difference/EXPERIMENTATION/
├── Evolution/
├── Contour/
└── Vectorised/
```

### Output & Metrics

For each test case, the following are computed:

| Metric | Description | Use Case |
|--------|-------------|----------|
| `max_vorticity` | Peak vorticity in domain | Intensity tracking |
| `circulation_total` | Total circulation (should conserve) | Validation |
| `enstrophy` | ∫ω² dA | Energy dissipation |
| `kinetic_energy` | ∫(u² + v²) dA | Flow energy |
| `run_time_s` | Simulation wall time | Performance |

### Comparison Across Test Cases

To compare multiple test cases:

```matlab
% Run each test case sequentially
for test_case = ["double_vortex", "three_vortex", "gaussian_merger"]
    experimentation.test_case = test_case;
    Analysis;
    pause(5);  % Give time to review results
end
```

Results are saved in mode-specific directories for easy comparison.

---

## Part 4: Machine Learning Framework for Vorticity Neutralization

### Research Objective

Develop ML-based optimization to identify structures that:
- **Absorb** vorticity energy most efficiently
- **Minimize** power input required
- **Operate** across multiple domain sizes/viscosity regimes
- **Generalize** to unseen vortex configurations

### 4.1 Physical Problem

**Goal:** Given a vorticity field, design absorber geometry that:
1. Extracts maximum energy per unit structure volume
2. Minimizes implementation cost (power, material, maintenance)
3. Works across domain sizes (scalability)

**Unknowns:**
- Optimal absorber geometry (shape, orientation, permeability)
- Placement strategy relative to vortex cores
- Parameter sensitivity across domains

### 4.2 ML Approach - Preliminary Framework

#### Phase 1: Data Generation
```
For each configuration:
  - Vortex type (single, pair, three, etc.)
  - Absorber geometry (cylinder, porous region, damping zone)
  - Domain size (64×64 to 2048×2048)
  - Viscosity (ν = 10⁻⁷ to 10⁻³)
  - Absorber parameters (position, size, permeability)
  
  Compute:
  - Energy dissipation rate (before absorber)
  - Energy dissipation rate (with absorber)
  - Efficiency = ΔE / (Structure Volume × Time)
  - Power required (pressure drop × flow rate)
  - Scalability (performance across domain sizes)
```

#### Phase 2: Feature Engineering
```
Input Features:
  - Vortex characteristics: 
    * Peak vorticity (ω_max)
    * Circulation (Γ)
    * Vortex core radius (r_c)
    * Separation distance (for pairs)
  
  - Domain characteristics:
    * Grid size (Nx, Ny)
    * Viscosity (ν)
    * Reynolds number (Re)
  
  - Absorber parameters:
    * Type (porous, solid, hybrid)
    * Geometry (circle, square, annulus, custom)
    * Position (x, y, radius from vortex)
    * Permeability (α for porous, 0 for solid)
    * Size (characteristic length, relative to Lx)

Output Targets:
  - Energy absorption efficiency (J/s per m³)
  - Power consumption (normalized)
  - Scalability score (performance consistency)
  - Generalization score (transfer to unseen configs)
```

#### Phase 3: Model Architecture

**Recommendation: Hybrid Neural Network**

```
Input Layer (12-15 features)
  ↓
Encoder (Extract vortex + domain features)
  Dense: 32 → 16 neurons
  ↓
Geometry Branch (Absorber parameter prediction)
  Dense: 16 → 8 → 4
  Activation: ReLU
  ↓
Efficiency Predictor (Output)
  Dense: 16 → 8 → 1
  Activation: sigmoid (normalize [0,1])
  
Loss: MSE (efficiency prediction) + L2 (regularization)
Optimizer: Adam (lr=0.001)
Epochs: 100-500 (depending on data size)
```

**Why Hybrid?**
- Interpretability: Can analyze feature importance
- Efficiency: Compact network, fast inference
- Physics-informed: Encode conservation laws as constraints

#### Phase 4: Training Strategy

1. **Generate Dataset**
   ```
   - Vortex types: 5 (single, pair, three, merger, counter-rotating)
   - Domain sizes: 4 (128, 256, 512, 1024)
   - Absorber variants: 10-20 per vortex type
   - Total samples: 2000-5000 simulations
   - Runtime: 3-7 days on GPU cluster
   ```

2. **Data Augmentation**
   - Rotation invariance: Rotate domain by θ ∈ [0°, 90°]
   - Symmetry: Exploit domain reflections
   - Scaling: Normalize features to unit variance

3. **Validation Strategy**
   - **Hold-out test set**: 20% of data, unseen vortex configs
   - **Domain generalization**: Train on 256×256, test on 512×512
   - **Transfer learning**: Pre-train on single vortex, fine-tune on pairs

4. **Success Metrics**
   - Prediction error: R² > 0.85 on hold-out test
   - Generalization: <10% performance drop on out-of-domain sizes
   - Interpretability: Identify top-5 important features
   - Efficiency gain: Best predicted absorber > current best by 20%

### 4.3 Implementation Roadmap

#### Stage 1: Proof of Concept (Weeks 1-4)
- [ ] Generate 500 training samples (single vortex only)
- [ ] Build baseline ML model (scikit-learn or PyTorch)
- [ ] Test on hold-out set (R² > 0.70)
- [ ] Document feature importance

#### Stage 2: Extended Validation (Weeks 5-8)
- [ ] Expand to 2000+ samples (multiple vortex types)
- [ ] Implement domain generalization tests
- [ ] Develop visualization of learned absorber patterns
- [ ] Compare ML predictions vs. ground truth

#### Stage 3: Optimization & Transfer (Weeks 9-12)
- [ ] Fine-tune hyperparameters
- [ ] Implement transfer learning (domain size generalization)
- [ ] Deploy as inverse model: given target efficiency → absorber design
- [ ] Create web interface or MATLAB integration

#### Stage 4: Physical Validation (Weeks 13+)
- [ ] ML-predicted absorbers in real simulations
- [ ] Bench against human-designed absorbers
- [ ] Uncertainty quantification (confidence intervals)
- [ ] Publication preparation

### 4.4 Absorber Models to Test

#### 1. Porous Region
```matlab
% Absorber: Zone with increased damping
% Parameter: α ∈ [0, 1] damping coefficient

u_modified = u * (1 - α);  % Reduce velocity
v_modified = v * (1 - α);
```
**Pros:** Simple, computational efficient  
**Cons:** Physical realism questionable

#### 2. Solid Cylinder
```matlab
% Absorber: Solid cylindrical obstacle
% Parameter: radius r, position (x, y)

omega[inside_cylinder] = 0;  % No vorticity inside
```
**Pros:** Physical, simple to implement  
**Cons:** No interaction with boundary layer

#### 3. Permeable Absorber (Hybrid)
```matlab
% Absorber: Annular region with controlled permeability
% Parameters: outer radius R_out, inner radius R_in, permeability α

velocity_reduction = 1 - α  % Inside annulus
omega_reduction = 1 - 0.5*α  % Partial vorticity dissipation
```
**Pros:** Tunable, balance between solid and porous  
**Cons:** More parameters to optimize

#### 4. Adaptive/Dynamic Absorber
```matlab
% Absorber strength varies with local vorticity
% alpha(x,y,t) = β * |ω(x,y,t)| / ω_max

% Stronger damping where vorticity is high
% Weaker where flow is weak (conserve useful circulation)
```
**Pros:** Energy-conscious, adaptive  
**Cons:** Requires real-time computation during simulation

### 4.5 Key Challenges & Solutions

| Challenge | Solution | Timeline |
|-----------|----------|----------|
| Computational cost | Use cached simulations, parallelization | Stage 1-2 |
| Feature selection | Domain knowledge + automated methods | Stage 2 |
| Generalization to unseen sizes | Domain generalization, meta-learning | Stage 3 |
| Physical realism | Compare against experimental data | Stage 4 |
| Interpretability | SHAP values, attention mechanisms | Throughout |

### 4.6 Expected Outcomes

**By end of project:**
1. ML model achieving **R² > 0.85** on test set
2. **Top-5 feature importance list** (e.g., "vortex separation distance" most important)
3. **Absorber design tool**: Input vortex config → Output optimal absorber
4. **Performance comparison**: ML-designed absorbers 15-30% more efficient than hand-tuned
5. **Scalability analysis**: Prediction accuracy across domain sizes 256²-1024²
6. **Publication**: 1-2 papers (ML methodology + application to vortex control)

### 4.7 Code Structure for ML Integration

```
Analysis/
├── Analysis.m                          (main driver)
├── Finite_Difference_Analysis.m        (solver, unchanged)
├── ML_VorticityControl/                (NEW: ML module)
│   ├── generate_training_data.py       → Runs simulations, logs metrics
│   ├── ml_model.py                     → PyTorch/TensorFlow model
│   ├── feature_engineering.py          → Preprocess data
│   ├── train_model.py                  → Training pipeline
│   ├── optimize_absorber.py            → Inverse design
│   ├── visualize_results.py            → Plot learned patterns
│   └── results/
│       ├── model_checkpoints/
│       ├── training_logs/
│       └── visualizations/
│
└── ml_config.yaml                      (hyperparameters, data paths)
```

**Integration with Analysis.m:**
```matlab
% New mode planned for future
run_mode = "ml_optimization";

ml_config.target_efficiency = 0.85;     % Desired efficiency
ml_config.vortex_type = "double_vortex";
ml_config.domain_size = 256;

% Calls Python backend to predict optimal absorber
optimal_absorber = run_ml_optimization(ml_config);
```

---

## Summary of Changes

### Files Modified
1. **Analysis.m**
   - Added "experimentation" mode to run_mode options
   - Added visualization settings (contour_method, vector_method)
   - Added experimentation configuration parameters
   - Implemented `run_experimentation_mode` function (85 lines)
   - Extended `initialise_omega` with 3 new IC types (150 lines)
   - Updated mode dispatch switch statement

2. **Finite_Difference_Analysis.m**
   - Enhanced contour plotting (lines 214-250)
     * Support for both 'contour' and 'contourf' methods
     * Configurable contour levels
   - Enhanced vector field visualization (lines 267-296)
     * Support for 'quiver' and 'streamlines' methods
     * Configurable subsampling and scaling
   - Read visualization settings from Parameters struct

### New Initial Conditions Available
- `vortex_pair`: Two counter-rotating vortices
- `multi_vortex`: Three or more vortices in system
- `counter_rotating_pair`: High-interaction vortex pair
- Enhanced `stretched_gaussian`: Anisotropic stretching support

### Configuration Parameters Added
```matlab
visualization.contour_method = "contourf";      % or "contour"
visualization.contour_levels = 25;
visualization.vector_method = "quiver";          % or "streamlines"
visualization.vector_subsampling = 4;
visualization.vector_scale = 1.0;
visualization.colormap = "turbo";

experimentation.test_case = "double_vortex";     % Select test
experimentation.save_summary = true;
experimentation.compute_metrics = true;
```

---

## Quick Start Guide

### 1. Run Experimentation Mode
```matlab
% Analysis.m
run_mode = "experimentation";
experimentation.test_case = "double_vortex";
Nx = 256; Ny = 256; nu = 1e-6;

% Run:
Analysis;
```

### 2. Change Visualization Method
```matlab
% For publication-quality figures:
visualization.contour_method = "contourf";
visualization.vector_method = "streamlines";
figures.dpi = 300;

% For fast iteration:
visualization.contour_method = "contour";
visualization.vector_method = "quiver";
visualization.vector_subsampling = 3;
```

### 3. Test Multiple Configurations
```matlab
% Test all initial conditions
test_cases = ["double_vortex", "three_vortex", "gaussian_merger"];
for test = test_cases
    experimentation.test_case = test;
    Analysis;
    pause(5);
end
```

### 4. Plan ML Framework
- Read Section 4 (ML Framework for Vorticity Neutralization)
- Start with Stage 1: Proof of Concept
- Use generated data from experimentation mode to seed training set
- Iterate: Simulations → Data → ML Model → Predictions → Validation

---

## Next Steps

1. **Immediate** (This week):
   - [ ] Test experimentation mode with each test case
   - [ ] Verify convergence figures are saved (they are!)
   - [ ] Compare contour/streamline visualization methods
   - [ ] Document favorite configurations

2. **Short-term** (Weeks 2-4):
   - [ ] Generate 500 baseline training samples
   - [ ] Implement basic ML model (scikit-learn)
   - [ ] Establish baseline metrics and data pipeline

3. **Medium-term** (Weeks 5-12):
   - [ ] Expand to 2000+ samples (multiple domains/vortex types)
   - [ ] Deploy neural network with domain generalization
   - [ ] Validate predictions against simulations
   - [ ] Optimize absorber designs

4. **Long-term** (3+ months):
   - [ ] Transfer learning for new domain sizes
   - [ ] Inverse design (efficiency target → absorber)
   - [ ] Physical validation and comparison
   - [ ] Publication and deployment

---

## References & Resources

### MATLAB Documentation
- [Contour plots](https://www.mathworks.com/help/matlab/ref/contour.html)
- [Filled contours](https://www.mathworks.com/help/matlab/ref/contourf.html)
- [Streamline visualization](https://www.mathworks.com/help/matlab/ref/streamline.html)
- [Quiver plots](https://www.mathworks.com/help/matlab/ref/quiver.html)

### ML Resources
- PyTorch: https://pytorch.org/docs/stable/
- TensorFlow/Keras: https://www.tensorflow.org/
- Scikit-learn: https://scikit-learn.org/
- SHAP for interpretability: https://github.com/slundberg/shap

### Physics References
- Vortex dynamics: Saffman, "Vortex Dynamics" (2nd Ed)
- Energy dissipation: Beaumont et al., "Viscous dissipation in 2D turbulence"
- ML for physics: Raissi et al., "Physics-Informed Neural Networks"

---

## Support & Troubleshooting

**Q: Figures not saving during convergence?**  
A: Confirmed working. Check that `convergence.save_iteration_figures = true` in Analysis.m

**Q: Contour not showing up?**  
A: Ensure streamfunction (psi) is computed. Check finite differences for dpsi/dx, dpsi/dy

**Q: Streamline visualization too dense/sparse?**  
A: Adjust `visualization.vector_subsampling` (larger = sparser, fewer lines)

**Q: Which test case to start with?**  
A: Start with "double_vortex" or "gaussian_merger" - simplest, most stable

**Q: How to design custom IC?**  
A: Edit `initialise_omega` function, add new case with your IC formula

**Q: Vorticity field looks weird?**  
A: Check domain bounds [0,Lx] × [0,Ly] and IC parameter ranges

---

**End of Guide**

For questions or issues, contact the development team or refer to the main CHANGELOG.md documentation.
