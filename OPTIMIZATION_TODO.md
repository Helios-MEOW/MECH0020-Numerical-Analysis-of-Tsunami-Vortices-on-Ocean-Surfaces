# OPTIMIZATION & DEVELOPMENT TODO LIST
## Tsunami Vortex Simulation Framework

**Last Updated:** February 3, 2026 (Updated after Priority 1 optimizations)  
**Status Legend:** ⬜ Not Started | 🟦 In Progress | ✅ Complete | 🚫 Blocked | 🔄 Needs Review

---

## 🔥 PRIORITY 1: IMMEDIATE OPTIMIZATIONS (This Week)

### ✅ 1.1 Implement Parallel Parameter Sweeps
**Impact:** 🔴 HIGH | **Effort:** 🟢 LOW | **Est. Time:** 2-4 hours | **Status:** COMPLETE

**Location:** `Scripts/Main/Analysis.m`, function `run_sweep_mode()`

**Changes Required:**
```matlab
% BEFORE (line ~1788):
for k = 1:numel(cases)
    params = cases(k);
    % ... simulation code
end

% AFTER:
parfor k = 1:numel(cases)
    params = cases(k);
    % ... simulation code (ensure thread-safe)
end
```

**Checklist:**
- [x] Add `parfor` to sweep loop (line 1752)
- [x] Added progress message for parallel execution
- [ ] Test with 2-4 cores (user testing required)
- [ ] Verify results consistency (user testing required)
- [ ] Benchmark speedup (user testing required)
- [x] Updated documentation with comment

**Expected Outcome:** 4-8x speedup on multi-core systems

**Changes Implemented:**
- Modified `run_sweep_mode()` at line ~1752
- Changed `for k = 1:numel(cases)` to `parfor k = 1:numel(cases)`
- Added parallel execution message
- Verified Parallel Computing Toolbox is available (R2025b)

---

### ✅ 1.2 Create Struct Factory Functions
**Impact:** 🟡 MED | **Effort:** 🟢 LOW | **Est. Time:** 4-6 hours | **Status:** COMPLETE

**New Files Created:**
- ✅ `Scripts/Infrastructure/create_default_parameters.m` (85 lines)
- ⬜ `Scripts/Infrastructure/create_convergence_settings.m` (deferred)
- ⬜ `Scripts/Infrastructure/create_visualization_settings.m` (deferred)

**Implementation:**
```matlab
% File: Scripts/Infrastructure/create_default_parameters.m
function params = create_default_parameters()
    params = struct(...
        'Lx', 10, ...
        'Ly', 10, ...
        'Nx', 128, ...
        'Ny', 128, ...
        'nu', 1e-6, ...
        'dt', 0.01, ...
        'Tfinal', 8, ...
        'ic_type', "stretched_gaussian", ...
        'ic_coeff', [2, 0.2]);
end
```

**Checklist:**
- [x] Create factory function for Parameters
- [x] Update Analysis.m to use factory (line ~284)
- [ ] Create factory for convergence settings (deferred)
- [ ] Create factory for visualization settings (deferred)
- [ ] Test all modes still work (user testing required)
- [x] Document usage with comments

**Refactored:** `Analysis.m` line ~284 now uses single-line factory call:
```matlab
Parameters = create_default_parameters();
```
This replaces 30+ lines of verbose struct initialization.

---

### 🚫 1.3 Implement Unique Identifier System
**Impact:** 🟡 MED | **Effort:** 🟢 LOW | **Est. Time:** 3-4 hours | **Status:** SKIPPED (per user request)

**New Function:** `Scripts/Infrastructure/generate_simulation_id.m`

**ID Format:**
```
{MODE}_{METHOD}_{GRID}_{IC}_{TIMESTAMP}_{HASH}

Example: CONV_FD_128x128_STRGAUSS_20260203_143022_A7F3
```

**Implementation:**
```matlab
function id = generate_simulation_id(Parameters, run_mode)
    mode_abbr = get_mode_abbreviation(run_mode);
    method_abbr = get_method_abbreviation(Parameters.analysis_method);
    grid_str = sprintf('%dx%d', Parameters.Nx, Parameters.Ny);
    ic_abbr = get_ic_abbreviation(Parameters.ic_type);
    timestamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
    hash = compute_param_hash(Parameters);
    
    id = sprintf('%s_%s_%s_%s_%s_%s', ...
        mode_abbr, method_abbr, grid_str, ic_abbr, timestamp, hash);
end
```

**Checklist:**
- [ ] SKIPPED - User requested to skip for now
- [ ] Will revisit in future optimization cycle

---

### ✅ 1.4 Add Preflight Validation Suite
**Impact:** 🔴 HIGH | **Effort:** 🟡 MED | **Est. Time:** 4-6 hours | **Status:** COMPLETE

**New File:** `Scripts/Infrastructure/validate_simulation_parameters.m`

**Validations to Add:**
1. CFL condition: `CFL = u_max * dt / min(dx, dy) < 1.0`
2. Diffusion stability: `D = ν * dt / dx² < 0.5`
3. Memory estimation: `Required_MB < Available_MB * 0.8`
4. Directory structure exists
5. Required functions on path
6. NaN checks in initial conditions

**Checklist:**
- [x] Create validation function
- [x] Add CFL check with stability thresholds
- [x] Add diffusion stability check
- [x] Add memory estimation (Windows support)
- [x] Add directory checks
- [x] Integrate into Analysis.m preflight (line ~1793)
- [x] Create validation report with colored output

**Enhanced:** `Analysis.m` preflight now calls comprehensive validation suite

---

## 📊 PRIORITY 1 OPTIMIZATION SUMMARY

**Completed:** 3/4 tasks (75%)  
**Skipped:** 1 task (Unique ID generation - per user request)  
**Time Invested:** ~6 hours  

**Expected Performance Gains:**
- 🚀 **4-8x speedup** on parameter sweeps (parfor parallelization)
- 📝 **30+ lines of code eliminated** (struct factory pattern)
- 🛡️ **Comprehensive preflight validation** prevents failed runs and wasted compute time

**Files Modified:**
1. [Scripts/Main/Analysis.m](Scripts/Main/Analysis.m) - 3 optimizations applied
   - Line ~284: Struct factory implementation
   - Line ~1752: Parallel sweep implementation
   - Line ~1793: Enhanced preflight validation
2. [Scripts/Infrastructure/create_default_parameters.m](Scripts/Infrastructure/create_default_parameters.m) - NEW (85 lines)
3. [Scripts/Infrastructure/validate_simulation_parameters.m](Scripts/Infrastructure/validate_simulation_parameters.m) - NEW (260 lines)

**Testing Required:**
- [ ] Run sweep mode with multiple cases to verify parfor speedup
- [ ] Run all modes (evolution, convergence, sweep, animation) to ensure factory works
- [ ] Verify validation catches invalid parameters (test with bad CFL, negative dt, etc.)
- [ ] Benchmark actual speedup with realistic parameter sweeps

**Next Steps:**
- Move to Priority 2 optimizations OR
- Test Priority 1 changes before proceeding

---

## 🎯 PRIORITY 2: SHORT-TERM IMPROVEMENTS (This Month)

### ⬜ 2.1 Multi-Sheet Excel Export System
**Impact:** 🟡 MED | **Effort:** 🟡 MED | **Est. Time:** 6-8 hours

**New File:** `Scripts/Infrastructure/export_multi_sheet_results.m`

**Sheet Structure:**
1. **Evolution** - Single simulation results
2. **Convergence** - Refinement studies with metadata
3. **Parameter_Sweeps** - Sweep configurations and results
4. **Sustainability** - Energy/hardware metrics
5. **Summary** - Aggregated statistics

**Implementation:**
```matlab
function export_multi_sheet_results(results_dir)
    filename = fullfile(results_dir, 'tsunami_complete_results.xlsx');
    
    % Load all CSV files
    evolution_data = load_mode_data('evolution', results_dir);
    convergence_data = load_mode_data('convergence', results_dir);
    sweep_data = load_mode_data('sweep', results_dir);
    sustainability_data = load_sustainability_data(results_dir);
    
    % Write sheets
    writetable(evolution_data, filename, 'Sheet', 'Evolution');
    writetable(convergence_data, filename, 'Sheet', 'Convergence');
    writetable(sweep_data, filename, 'Sheet', 'Parameter_Sweeps');
    writetable(sustainability_data, filename, 'Sheet', 'Sustainability');
    
    % Apply formatting
    apply_conditional_formatting(filename);
end
```

**Checklist:**
- [ ] Create export function
- [ ] Implement data consolidation
- [ ] Add conditional formatting (method colors)
- [ ] Add filterable headers
- [ ] Create summary statistics sheet
- [ ] Test with existing data
- [ ] Document usage

---

### ⬜ 2.2 Automated Test Suite
**Impact:** 🔴 HIGH | **Effort:** 🟡 MED | **Est. Time:** 8-12 hours

**New File:** `tests/run_all_tests.m`

**Test Categories:**
1. **Unit Tests:** Individual function validation
2. **Integration Tests:** Mode execution end-to-end
3. **Regression Tests:** Compare against baseline results
4. **Performance Tests:** Benchmark timings

**Test Functions to Create:**
```
tests/
├── test_ic_generation.m
├── test_convergence_metrics.m
├── test_parameter_validation.m
├── test_cache_consistency.m
├── test_richardson_extrapolation.m
├── test_dual_refinement.m
├── test_sustainability_tracking.m
├── test_struct_schemas.m
└── test_ui_integration.m
```

**Example Test:**
```matlab
function test_ic_generation()
    ic_types = ["stretched_gaussian", "vortex_pair", "multi_vortex"];
    X = meshgrid(linspace(-5, 5, 50));
    Y = X';
    
    for i = 1:length(ic_types)
        omega = initialise_omega(X, Y, ic_types(i), []);
        assert(all(isfinite(omega(:))), 'IC contains NaN/Inf');
        assert(size(omega, 1) == size(X, 1), 'Size mismatch');
    end
    fprintf('✅ IC generation tests passed\n');
end
```

**Checklist:**
- [ ] Create test directory structure
- [ ] Write IC generation tests
- [ ] Write convergence metric tests
- [ ] Write parameter validation tests
- [ ] Write cache tests
- [ ] Create test runner script
- [ ] Set up CI/CD integration (optional)
- [ ] Document test coverage

---

### ⬜ 2.3 Convergence Caching Optimization
**Impact:** 🟡 MED | **Effort:** 🟡 MED | **Est. Time:** 4-6 hours

**Location:** `Scripts/Main/Analysis.m`, function `run_case_metric_cached()`

**Enhancements:**
1. Pre-compute all cache keys
2. Batch cache lookups
3. Persistent cache to disk
4. Cache analytics (hit rate)

**Implementation:**
```matlab
% Pre-compute cache keys
cache_keys = cell(length(N_values), 1);
for i = 1:length(N_values)
    cache_keys{i} = sprintf('N%d_dt%.6e', N_values(i), dt_values(i));
end

% Batch check
uncached_idx = find(~cellfun(@(k) isfield(cache, k), cache_keys));

% Run only uncached
for i = uncached_idx'
    [metric, row, figs] = run_case_metric(Parameters, N_values(i), dt_values(i));
    cache.(cache_keys{i}) = struct('metric', metric, 'row', row, 'figs', figs);
end
```

**Checklist:**
- [ ] Implement batch cache checking
- [ ] Add cache persistence (save/load)
- [ ] Add cache hit rate logging
- [ ] Add cache invalidation logic
- [ ] Optimize cache key generation
- [ ] Test with convergence study

---

### ⬜ 2.4 ML Data Collection Documentation
**Impact:** 🟡 MED | **Effort:** 🟢 LOW | **Est. Time:** 3-4 hours

**New File:** `docs/ML_DATA_FORMAT.md`

**Content:**
1. Feature definitions
2. Data schemas
3. Collection procedures
4. Storage format
5. Example pipelines

**Checklist:**
- [ ] Document feature extraction process
- [ ] Define ML-ready data format
- [ ] Create example training dataset
- [ ] Document preprocessing steps
- [ ] Add data validation scripts

---

## 🚀 PRIORITY 3: MEDIUM-TERM ENHANCEMENTS (3 Months)

### ⬜ 3.1 Gaussian Process Surrogate Modeling
**Impact:** 🔴 HIGH | **Effort:** 🔴 HIGH | **Est. Time:** 2-3 days

**New File:** `Scripts/ML/surrogate_parameter_sweep.m`

**Algorithm:**
```matlab
function [optimal_params, acquisition_points] = surrogate_parameter_sweep(Parameters, param_ranges)
    % 1. Initial samples (Latin Hypercube Sampling)
    initial_points = lhsdesign(10, length(param_ranges));
    
    % 2. Run simulations at initial points
    for i = 1:size(initial_points, 1)
        results(i) = run_simulation(scale_params(initial_points(i,:), param_ranges));
    end
    
    % 3. Train GP model
    gprMdl = fitrgp(initial_points, [results.energy]);
    
    % 4. Adaptive acquisition (Expected Improvement)
    while num_simulations < budget
        next_point = maximize_expected_improvement(gprMdl, param_ranges);
        result = run_simulation(scale_params(next_point, param_ranges));
        gprMdl = update_model(gprMdl, next_point, result.energy);
    end
    
    optimal_params = find_optimum(gprMdl);
end
```

**Checklist:**
- [ ] Implement Latin Hypercube Sampling
- [ ] Create GP training wrapper
- [ ] Implement acquisition function
- [ ] Add uncertainty quantification
- [ ] Create visualization tools
- [ ] Benchmark against full sweep
- [ ] Document methodology

---

### ⬜ 3.2 Obstacle Geometry Parameterization
**Impact:** 🔴 HIGH | **Effort:** 🔴 HIGH | **Est. Time:** 2-3 days

**New File:** `Scripts/ML/obstacle_geometry.m`

**Geometry Types:**
1. **Circle:** `[x, y, r]`
2. **Ellipse:** `[x, y, a, b, θ]`
3. **Rectangle:** `[x, y, w, h, θ]`
4. **Polygon:** `[x₁, y₁, x₂, y₂, ..., xₙ, yₙ]`

**Implementation:**
```matlab
function omega_modified = apply_obstacle(omega, X, Y, obstacle)
    switch obstacle.type
        case 'circle'
            mask = sqrt((X - obstacle.x).^2 + (Y - obstacle.y).^2) < obstacle.r;
        case 'ellipse'
            % Rotate and scale
            X_rot = (X - obstacle.x) * cos(obstacle.theta) + (Y - obstacle.y) * sin(obstacle.theta);
            Y_rot = -(X - obstacle.x) * sin(obstacle.theta) + (Y - obstacle.y) * cos(obstacle.theta);
            mask = (X_rot / obstacle.a).^2 + (Y_rot / obstacle.b).^2 < 1;
    end
    
    omega_modified = omega .* ~mask;  % Set vorticity to zero inside obstacle
end
```

**Checklist:**
- [ ] Implement geometry types
- [ ] Create obstacle application function
- [ ] Add boundary condition handling
- [ ] Create visualization tools
- [ ] Test with simulations
- [ ] Document API

---

### ⬜ 3.3 Energy Dissipation Benchmark Suite
**Impact:** 🔴 HIGH | **Effort:** 🟡 MED | **Est. Time:** 1-2 days

**New File:** `Scripts/ML/energy_dissipation_benchmark.m`

**Benchmark Cases:**
1. **No obstacle** (baseline)
2. **Circular obstacles** (varying radius)
3. **Elliptical obstacles** (varying aspect ratio)
4. **Rectangular obstacles** (varying orientation)
5. **Multi-obstacle configurations**

**Metrics to Track:**
- Total energy dissipated: `E_diss = E_initial - E_final`
- Dissipation rate: `dE/dt`
- Obstacle efficiency: `E_diss / Obstacle_volume`
- Flow field distortion

**Checklist:**
- [ ] Define benchmark geometries
- [ ] Run baseline simulations
- [ ] Compute dissipation metrics
- [ ] Create database of results
- [ ] Visualize energy landscapes
- [ ] Document findings

---

### ⬜ 3.4 ML Feature Extraction Pipeline
**Impact:** 🔴 HIGH | **Effort:** 🟡 MED | **Est. Time:** 1-2 days

**New File:** `Scripts/ML/extract_ml_features.m`

**Feature Categories:**
1. **Statistical:** mean, std, skewness, kurtosis
2. **Spatial:** gradients, curvature, centroids
3. **Spectral:** FFT energy distribution
4. **Geometric:** eccentricity, orientation
5. **Temporal:** decay rates, frequencies

**Implementation:**
```matlab
function features = extract_ml_features(omega_snaps, psi_snaps, Parameters)
    features = struct();
    
    % Vorticity statistics
    features.omega_mean = mean(omega_snaps(:));
    features.omega_std = std(omega_snaps(:));
    features.omega_skewness = skewness(omega_snaps(:));
    features.omega_kurtosis = kurtosis(omega_snaps(:));
    
    % Spatial gradients
    [omega_x, omega_y] = gradient(omega_snaps(:,:,end));
    features.gradient_magnitude = mean(sqrt(omega_x.^2 + omega_y.^2), 'all');
    
    % Spectral content
    omega_fft = fft2(omega_snaps(:,:,end));
    features.spectral_energy = sum(abs(omega_fft(:)).^2);
    
    % Geometric properties
    features.centroid_x = sum(X(:) .* omega_snaps(:)) / sum(omega_snaps(:));
    features.eccentricity = compute_eccentricity(omega_snaps);
    
    % Temporal evolution
    features.decay_rate = fit_exponential_decay(squeeze(mean(omega_snaps, [1 2])));
end
```

**Checklist:**
- [ ] Implement all feature extractors
- [ ] Add feature normalization
- [ ] Create feature selection tools
- [ ] Test on existing data
- [ ] Document feature definitions
- [ ] Create visualization dashboard

---

## 🌟 PRIORITY 4: LONG-TERM INNOVATIONS (6+ Months)

### ⬜ 4.1 Deep RL Agent for Geometry Optimization
**Impact:** 🔴 HIGH | **Effort:** 🔴 HIGH | **Est. Time:** 2-3 weeks

**Approach:** Train agent to discover optimal obstacle configurations

**State Space:** Vorticity field (Nx × Ny)
**Action Space:** Obstacle parameters [x, y, shape_params]
**Reward:** Energy dissipated

**Implementation Framework:**
- **Environment:** Custom MATLAB/Python hybrid
- **Algorithm:** Proximal Policy Optimization (PPO)
- **Training:** 10k-50k episodes

**Checklist:**
- [ ] Design RL environment API
- [ ] Implement state/action representations
- [ ] Define reward function
- [ ] Set up PPO training
- [ ] Train baseline agent
- [ ] Hyperparameter tuning
- [ ] Validation on test cases
- [ ] Compare to analytical solutions

---

### ⬜ 4.2 Proper Orthogonal Decomposition (POD) ROM
**Impact:** 🔴 HIGH | **Effort:** 🔴 HIGH | **Est. Time:** 2-3 weeks

**Goal:** 100-1000x speedup via reduced-order modeling

**Algorithm:**
```
1. Collect snapshots: Ω = [ω₁, ω₂, ..., ωₙ]
2. Compute SVD: Ω = UΣVᵀ
3. Truncate: U_r = U(:, 1:r)  (r << Nx*Ny)
4. Project equations: dα/dt = f(α)  where ω ≈ U_r * α
5. Solve reduced system (r equations instead of Nx*Ny)
```

**Checklist:**
- [ ] Implement snapshot collection
- [ ] Add SVD decomposition
- [ ] Develop projection operators
- [ ] Implement reduced solver
- [ ] Validate accuracy
- [ ] Benchmark speedup
- [ ] Document methodology

---

### ⬜ 4.3 Online Real-Time Dashboard
**Impact:** 🟡 MED | **Effort:** 🔴 HIGH | **Est. Time:** 2-3 weeks

**Technology Stack:**
- **Backend:** MATLAB Production Server or Python Flask
- **Frontend:** React.js or Vue.js
- **Database:** PostgreSQL for results storage
- **Real-time:** WebSockets for live updates

**Features:**
- Live simulation monitoring
- Parameter configuration interface
- Result visualization
- Sustainability metrics dashboard
- Multi-user support

**Checklist:**
- [ ] Design system architecture
- [ ] Implement backend API
- [ ] Create frontend interface
- [ ] Add real-time updates
- [ ] Integrate with simulation framework
- [ ] Deploy to server
- [ ] User testing

---

### ⬜ 4.4 Academic Publication: Sustainability Framework
**Impact:** 🔴 HIGH | **Effort:** 🟡 MED | **Est. Time:** 1-2 months

**Title:** "Quantifying the Hidden Costs of Numerical Simulations: A Sustainability Framework for CFD Research"

**Sections:**
1. Introduction - The ignored cost of setup
2. Methodology - Hardware monitoring approach
3. Results - Energy scaling models
4. Case Study - Tsunami vortex simulations
5. Discussion - Implications for reproducibility

**Checklist:**
- [ ] Collect comprehensive sustainability data
- [ ] Perform statistical analysis
- [ ] Create figures/tables
- [ ] Write manuscript
- [ ] Submit to journal (e.g., J. Comp. Phys.)
- [ ] Respond to reviews

---

## 📋 MAINTENANCE & CLEANUP TASKS

### ⬜ M.1 Remove Redundant/Old Features
**Est. Time:** 4-6 hours

**Items to Review:**
- [ ] Identify deprecated functions
- [ ] Remove commented-out code blocks
- [ ] Clean up unused global variables
- [ ] Remove obsolete test files
- [ ] Update function signatures

---

### ⬜ M.2 Consistent NaN Handling
**Est. Time:** 6-8 hours

**Locations to Fix:**
- [ ] `Scripts/Main/Analysis.m` - Convergence metric initialization
- [ ] `Scripts/Methods/Finite_Difference_Analysis.m` - Diagnostics
- [ ] `Scripts/Main/AdaptiveConvergenceAgent.m` - Metric validation

**Pattern:**
```matlab
% BEFORE:
if ~isfinite(metric)
    metric = NaN;  % Silently sets to NaN
end

% AFTER:
if ~isfinite(metric)
    warning('Metric non-finite at N=%d. Possible instability.', N);
    metric = NaN;
end
```

---

### ⬜ M.3 Comprehensive Documentation Update
**Est. Time:** 8-12 hours

**Files to Update:**
- [ ] README.md - Add optimization guide
- [ ] Tsunami_Vortex_Analysis_Complete_Guide.ipynb - Update all sections
- [ ] OPTIMIZATION_SUMMARY.md - Keep current
- [ ] Add API reference documentation
- [ ] Create developer contribution guide

---

### ⬜ M.4 Code Style Standardization
**Est. Time:** 4-6 hours

**Standards to Apply:**
- [ ] Consistent function header format
- [ ] Standard variable naming (camelCase vs snake_case)
- [ ] Consistent indentation (4 spaces)
- [ ] Line length limit (100-120 chars)
- [ ] Comment style guide

---

## 📊 PROGRESS TRACKING

### Week 1 (Feb 3-9, 2026)
- [ ] Priority 1.1: Parallel sweeps
- [ ] Priority 1.2: Struct factories
- [ ] Priority 1.3: Unique IDs
- [ ] Priority 1.4: Preflight validation

### Month 1 (Feb 2026)
- [ ] Priority 2.1: Multi-sheet Excel
- [ ] Priority 2.2: Test suite
- [ ] Priority 2.3: Cache optimization
- [ ] Priority 2.4: ML documentation

### Quarter 1 (Feb-Apr 2026)
- [ ] Priority 3.1: GP surrogate
- [ ] Priority 3.2: Obstacle geometry
- [ ] Priority 3.3: Energy benchmarks
- [ ] Priority 3.4: ML features

### Long-Term (2026+)
- [ ] Priority 4.1: Deep RL
- [ ] Priority 4.2: POD ROM
- [ ] Priority 4.3: Online dashboard
- [ ] Priority 4.4: Publication

---

## 🎯 KEY PERFORMANCE INDICATORS

### Computational Efficiency
- **Baseline:** Current sweep time for 20 simulations
- **Target:** 4-8x speedup after parallelization
- **Metric:** Wall time per sweep

### Code Quality
- **Baseline:** No automated testing
- **Target:** 80% test coverage
- **Metric:** % functions with unit tests

### Data Management
- **Baseline:** Separate CSV files
- **Target:** Consolidated multi-sheet workbook
- **Metric:** Ease of analysis (user survey)

### ML Readiness
- **Baseline:** Raw simulation data
- **Target:** Structured feature database
- **Metric:** Time to train first model

---

**Last Updated:** February 3, 2026  
**Next Review:** Weekly (every Monday)
