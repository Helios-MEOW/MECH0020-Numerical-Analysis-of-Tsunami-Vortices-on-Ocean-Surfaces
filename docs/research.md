# MECH0020 Tsunami Vortex Research Notes

**Purpose:** Document unviable/experimental setting combinations, future work constraints, and compatibility matrices for the MECH0020 tsunami vortex numerical simulation repository.

**Last Updated:** 2026-02-08

---

## Table of Contents

1. [Method/Mode Compatibility Matrix](#methodmode-compatibility-matrix)
2. [Unviable Combinations & Constraints](#unviable-combinations--constraints)
3. [Experimental Features](#experimental-features)
4. [Future Work](#future-work)
5. [Known Limitations](#known-limitations)

---

## Method/Mode Compatibility Matrix

| Method | Evolution | Convergence | ParameterSweep | Plotting | Notes |
|--------|-----------|-------------|----------------|----------|-------|
| **FD (Finite Difference)** | ✅ Supported | ✅ Supported | ✅ Supported | ✅ Supported | Fully implemented with Arakawa schemes |
| **Spectral (FFT)** | ⚠️ Experimental | ❌ Not Implemented | ❌ Not Implemented | ❌ Not Implemented | Stub exists in Spectral_Analysis.m |
| **FV (Finite Volume)** | ⚠️ Experimental | ❌ Not Implemented | ❌ Not Implemented | ❌ Not Implemented | Stub exists in Finite_Volume_Analysis.m |
| **Variable Bathymetry** | ⚠️ Special Mode | ❌ Not Implemented | ❌ Not Implemented | ❌ Not Implemented | Treated as separate solver, not mode flag |

**Legend:**
- ✅ Fully supported and tested
- ⚠️ Experimental/unstable; may not work correctly
- ❌ Not yet implemented

---

## Unviable Combinations & Constraints

### 1. Spectral Methods (FFT)

**Status:** Stub implementation only

**Constraints:**
- Spectral_Analysis.m exists but is not connected to ModeDispatcher
- Requires periodic boundary conditions (incompatible with Dirichlet/Neumann BCs)
- FFT-based Poisson solver needed for streamfunction
- No mode implementations (Evolution, Convergence, etc.)

**Error Code:** `SOL-SP-0001` if selected via ModeDispatcher

**Recommendation:** Use FD method until Spectral fully implemented

---

### 2. Finite Volume Methods (FV)

**Status:** Stub implementation only

**Constraints:**
- Finite_Volume_Analysis.m exists but not connected to ModeDispatcher
- Requires flux reconstruction and upwinding logic
- Conservative form of vorticity equation needed
- No mode implementations

**Error Code:** `SOL-FV-0001` if selected via ModeDispatcher

**Recommendation:** Use FD method until FV fully implemented

---

### 3. Variable Bathymetry

**Status:** Separate solver; not integrated as mode flag

**Current Implementation:**
- `Variable_Bathymetry_Analysis.m` is a standalone solver
- Should be refactored to be a "mode/environment" flag applicable to methods
- Currently requires manual invocation, not accessible via ModeDispatcher

**Compatibility:**
- ⚠️ May conflict with periodic boundary conditions
- ⚠️ Requires careful handling of depth variations in numerical schemes
- ⚠️ Not tested with Convergence or ParameterSweep modes

**Recommendation:** Treat as experimental feature; framework redesign needed

---

### 4. Boundary Conditions

**Current Implementation:**
- Periodic (wrap) boundaries implemented
- Dirichlet/Neumann boundaries not fully tested
- "Ocean-like boundary" (proposed) not implemented

**Constraints:**
- Spectral methods require periodic BCs
- Ocean boundary conditions require:
  - Physical boundary models (e.g., radiation conditions)
  - Method-specific implementations
  - Validation against analytical solutions

**Recommendation:** Use periodic boundaries for now; ocean BCs are future work

---

### 5. Multi-Vortex Initial Conditions

**Status:** Experimental

**Current Support:**
- Single vortex ICs (Lamb-Oseen, Gaussian) fully supported
- Multi-vortex capability partially implemented in `disperse_vortices.m`
- UI supports multi-vortex count, but type-per-vortex is experimental

**Constraints:**
- Automatic position seeding may cause vortex overlap or boundary proximity issues
- Different vortex types (e.g., Gaussian + Lamb-Oseen) not fully tested
- Stability depends on vortex spacing and grid resolution

**Recommendation:** Single vortex for production; multi-vortex for research exploration

---

## Experimental Features

### 1. Adaptive Convergence Agent

**Status:** Functional but experimental

**Description:**
- Intelligent mesh refinement using learning-based navigation
- `run_adaptive_convergence.m` and `AdaptiveConvergenceAgent.m`
- Adaptively selects mesh resolutions based on convergence patterns

**Constraints:**
- Assumes convergence rate patterns from preflight runs
- May not work well for highly nonlinear or chaotic ICs
- Requires manual tolerance tuning

**Recommendation:** Use for research; verify results with manual convergence studies

---

### 2. Sustainability Monitoring

**Status:** Functional with external dependencies

**Description:**
- Energy sustainability analysis via `EnergySustainabilityAnalyzer.m`
- Hardware monitoring via `HardwareMonitorBridge.m` and `iCUEBridge.m`
- Tracks CPU, GPU, power consumption during simulations

**Constraints:**
- Requires LibreHardwareMonitor (Windows)
- Requires iCUE software (for Corsair hardware)
- May not work on all systems
- Performance overhead (~5-10%)

**Error Codes:**
- `MON-SUS-0001`: Hardware monitor unavailable
- `MON-SUS-0002`: iCUE bridge unavailable

**Recommendation:** Disable if not needed; optional feature

---

## Future Work

### 1. UI Enhancements

**Required:**
- Verify exactly 3 tabs (Configuration, Live Monitor, Figures & Recreate)
- Implement preflight validation panel with green/red indicators
- Smart settings visibility (hide irrelevant controls based on method/mode)
- Dark theme enforcement
- Grid layout throughout (no ad-hoc Position properties)

**Current Status:**
- UIController.m uses grid layout and has Developer Mode
- Tab structure exists but may not match exact 3-tab specification
- Preflight validation logic needs implementation
- Settings visibility logic needs implementation

**Priority:** High (usability)

---

### 2. Plotting & Animation

**Required:**
- Decouple animation FPS from snapshot tiling
- Convergence mode high-frame animation (60 snapshots)
- Frame logic separation (evolution snapshots vs animation frames)

**Current Status:**
- Evolution mode: static tiled plots based on snapshots
- Animation FPS may be coupled with snapshot count (needs verification)
- Convergence mode animation behavior unclear

**Priority:** Medium (affects output quality)

---

### 3. Method Consolidation

**Proposal:**
- Consolidate Spectral and FV as "method" options in dispatcher
- Variable Bathymetry as "environment flag" not separate solver
- Unified interface: `run_simulation_with_method(method, mode, environment_flags, ...)`

**Benefits:**
- Reduces code duplication
- Clearer method/mode/environment separation
- Easier to add new methods

**Priority:** Low (architectural improvement, not blocking)

---

### 4. Testing Expansion

**Needed:**
- Unit tests for Spectral and FV (when implemented)
- Integration tests for Variable Bathymetry
- Multi-vortex IC validation tests
- Boundary condition tests (Dirichlet, Neumann, ocean)
- Performance/scalability tests (large grids, long time integration)

**Current Coverage:**
- FD Evolution: ✅
- FD Convergence: ✅
- FD ParameterSweep: ✅
- Static analysis: ✅
- UI contract checks: ✅

**Priority:** Medium (quality assurance)

---

## Known Limitations

### 1. Grid Resolution

**Constraint:** Memory and computational limits

- Grids larger than ~1024×1024 may exceed MATLAB memory on typical workstations
- Sparse grids not implemented
- Adaptive mesh refinement not implemented (except convergence agent)

**Recommendation:** Use grid resolution appropriate for problem; run convergence studies

---

### 2. Time Integration

**Constraint:** Explicit time-stepping only

- Forward Euler used for time integration
- CFL condition must be satisfied (CFL < 1, ideally CFL < 0.5)
- No implicit or semi-implicit schemes implemented

**Recommendation:** Monitor CFL number; reduce dt if instability occurs

---

### 3. Parallelization

**Constraint:** Single-threaded execution

- No GPU acceleration
- No multi-threading or distributed computing
- MATLAB implicit parallelization for linear algebra only

**Recommendation:** Use appropriate grid size for single-node execution; HPC integration is future work

---

### 4. Validation Data

**Constraint:** Limited analytical solutions for comparison

- Lamb-Oseen vortex decay has analytical solution (used for validation)
- Complex multi-vortex flows lack analytical benchmarks
- Experimental data not included

**Recommendation:** Use Lamb-Oseen for code verification; compare with published results for complex cases

---

## References

See [research_log.md](research_log.md) for detailed literature references and research notes.

---

**Maintained by:** MECH0020 Development Team
**Contact:** See main README for contact information
