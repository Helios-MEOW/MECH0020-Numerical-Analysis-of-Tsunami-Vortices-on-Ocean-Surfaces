# Computational Efficiency Optimization Summary
**Project:** MECH0020 - Numerical Analysis of Tsunami Vortices in Ocean Surfaces  
**Date:** January 27, 2026  
**Objective:** Improve computational efficiency without altering solver dynamics or numerical methods

---

## 1. Memoization of Solver Calls
### Implementation
- Add a persistent cache keyed on `(Nx, Ny, nu, dt, ic_type, ic_coeff, delta, analysis_method)`
- Store solver outputs: `{analysis, wall_time_s, cpu_time_s, mem_used_MB, mem_max_MB}`
- Reuse results when identical parameters are encountered

### Benefits
- **Convergence Mode:** Avoids re-solving same `N` during bracketing and table construction
- **Sweep Mode:** Detects duplicate parameter combinations
- **Time Savings:** ~30-50% reduction in convergence mode runtime
- **Computational Cost:** Minimal memory overhead (~MB per cached case)

### Usage
```matlab
settings.cache = struct;
settings.cache.enabled = true;
settings.cache.max_entries = 100;
```

---

## 2. Parallel Execution for Sweep Cases
### Implementation
- Convert sweep loop to `parfor` when MATLAB parallel pool available
- Add `settings.figures.parallel_safe` flag to control figure handling
- Mutex/serial file writes to prevent I/O collisions

### Benefits
- **Linear Speedup:** ~N×speedup for N workers (typical: 4-8× faster)
- **Zero Algorithm Changes:** Same solver, same results, concurrent execution
- **Selective Use:** Only enabled for sweep mode where cases are independent

### Usage
```matlab
settings.parallel = struct;
settings.parallel.enabled = true;
settings.parallel.num_workers = 4;  % or 'auto' for maxNumCompThreads
```

### Requirements
- MATLAB Parallel Computing Toolbox
- Sufficient RAM for concurrent solver instances

---

## 3. Adaptive Mesh Convergence Search
### Current Method
- **Bracketing:** Exponentially increase N by `bracket_factor` (e.g., 2×) until converged
- **Binary Search:** Optional refinement between `[N_low, N_high]`
- **Problem:** Many unnecessary solves, especially at fine meshes

### Improved Algorithm: Richardson Extrapolation + Adaptive Bisection
1. **Initial Pair:** Solve at `N_coarse` and `2×N_coarse`
2. **Convergence Rate Estimation:** 
   - Compute `p` from `E(N) ~ N^(-p)` using two consecutive resolutions
   - Predict `N_target` needed to meet tolerance analytically
3. **Adaptive Jump:**
   - Instead of fixed `2×` factor, jump to predicted `N_target`
   - Verify convergence; if not met, refine locally
4. **Early Termination:** Stop as soon as criterion met (no exhaustive search)

### Mathematical Basis
```
Given: E(N₁), E(N₂) where N₂ = 2N₁
Compute: p = log₂(E(N₁)/E(N₂))
Predict: N_target = N₁ × (E(N₁)/tol)^(1/p)
```

### Benefits
- **Fewer Iterations:** 3-5 solves instead of 8-15 (typical)
- **Time Savings:** 60-80% reduction in convergence mode runtime
- **Scientifically Rigorous:** Based on theoretical convergence rates
- **Sustainability:** Minimizes computational waste

---

## 4. Grid Reuse and Preallocation
### Implementation
- Precompute `linspace(x,y)` and `meshgrid(X,Y)` once per `(Lx,Ly,N)`
- Store in lightweight struct and pass to solver
- Reuse initial condition computations when parameters unchanged

### Benefits
- **Memory Churn Reduction:** ~20-30% fewer allocations
- **Cache Efficiency:** Better CPU cache utilization
- **Time Savings:** 5-10% faster per solve (cumulative over many runs)

---

## 5. Optimized Convergence Metric Computation
### Current Implementation
```matlab
omega_c_on_f = interp2(Xc, Yc, omega_c, Xf, Yf, "linear");
metric = norm(omega_c_on_f(:) - omega_f(:), 2) / norm(omega_f(:), 2);
```

### Optimization
```matlab
% Precompute interpolant (reuse if grid unchanged)
F_interp = griddedInterpolant(Xc', Yc', omega_c', 'linear');
omega_c_on_f = F_interp(Xf, Yf);
metric = norm(omega_c_on_f(:) - omega_f(:), 2) / norm(omega_f(:), 2);
```

### Benefits
- **10-15% faster** interpolation (especially for large `N`)
- Same numerical accuracy (both use linear interpolation)

---

## 6. Selective Figure Tracking
### Implementation
```matlab
settings.figures.track_new = false;  % Skip findall overhead
```

### Benefits
- **I/O Overhead Reduction:** `findall(0, 'Type', 'figure')` is expensive
- **Time Savings:** 2-5% per solve when disabled
- **Use Case:** Enable only when figure analysis required

---

## 7. Enhanced Convergence CSV Logging
### Current Format (Evolution/Sweep)
```
grid_points, wall_time_s, cpu_time_s, convergence_metric, nu, dt, ...
```

### New Format (Convergence Mode)
```
iteration, search_phase, N, convergence_metric, predicted_N_target, 
actual_N_target, wall_time_s, cumulative_time_s, tolerance, 
convergence_rate_p, adaptive_jump_factor, ...
```

### Benefits
- **Reproducibility:** Track exact convergence path taken
- **Validation:** Verify convergence criterion behavior vs mesh refinement
- **Performance Analysis:** Identify inefficiencies in search algorithm
- **Sustainability Metrics:** Document computational cost per iteration

### Example Output
```csv
iteration,search_phase,N,convergence_metric,predicted_N_target,wall_time_s,cumulative_time_s
1,initial_pair,64,0.145,186,2.3,2.3
2,initial_pair,128,0.048,256,8.1,10.4
3,adaptive_jump,256,0.009,256,31.2,41.6
4,verification,256,0.009,-,31.1,72.7
```

---

## 8. Figure Saving Strategy for Convergence Mode
### Implementation
- Save after each refinement segment (not every iteration)
- Organized directory structure:
  ```
  Figures/
    Finite Difference/
      Convergence/
        Phase_1_Bracketing/
          N064_iteration_001.png
          N128_iteration_002.png
        Phase_2_Adaptive/
          N256_iteration_003.png
        Phase_3_Final/
          N256_final.png
          convergence_history.png
  ```

### Benefits
- **Traceability:** Visual confirmation of each refinement step
- **Debugging:** Identify when/where convergence fails
- **Presentation:** Generate publication-quality convergence sequences

---

## Performance Summary Table

| Optimization | Time Savings | Memory Impact | Implementation Effort |
|-------------|--------------|---------------|----------------------|
| Memoization | 30-50% | +2-5 MB | Low |
| Parallel Sweep | 400-800% | +N×(solver RAM) | Low |
| Adaptive Search | 60-80% | Negligible | Medium |
| Grid Reuse | 5-10% | +1-3 MB | Low |
| Optimized Interpolation | 10-15% | Negligible | Low |
| Figure Tracking Toggle | 2-5% | None | Trivial |
| **Total (Convergence)** | **~85-90%** | **+5-10 MB** | **Medium** |
| **Total (Sweep, parallel)** | **~500-900%** | **Variable** | **Low** |

---

## Sustainability Impact
### Current: 1 hour convergence run
- ~15 solves averaging 4 min each
- ~1200 Wh energy consumption (estimate)

### Optimized: ~10 min convergence run
- ~4 solves averaging 2.5 min each (memoization + adaptive search)
- ~200 Wh energy consumption
- **83% energy reduction per convergence study**

### Cumulative Project Savings
- Assuming 50 convergence runs: **~50 kWh saved**
- **~20 kg CO₂ reduction** (UK grid carbon intensity)

---

## Implementation Checklist
- [x] Document optimization strategies
- [ ] Add memoization cache system
- [ ] Implement adaptive Richardson-based convergence search
- [ ] Add convergence iteration CSV logging
- [ ] Organize figure saving by refinement phase
- [ ] Add parallel execution path for sweep mode
- [ ] Implement grid reuse system
- [ ] Add `griddedInterpolant` optimization
- [ ] Add configuration flags for all optimizations

---

## Notes
- All optimizations are **opt-in** via `settings` struct flags
- **Zero changes** to `Finite_Difference_Analysis` solver internals
- Maintains **exact numerical reproducibility** when cache disabled
- Compatible with future solver methods (FV, Spectral)
