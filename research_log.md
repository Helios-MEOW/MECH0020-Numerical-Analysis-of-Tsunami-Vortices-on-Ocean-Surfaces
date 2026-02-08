# MECH0020 Research Log

**Purpose:** Document all research sources, literature references, and implementation notes collected during development of the MECH0020 tsunami vortex numerical simulation repository.

**Format:** Notion-compatible Markdown with Vancouver-style citations

**Last Updated:** 2026-02-08

---

## 📚 Table of Contents

- [Numerical Methods](#numerical-methods)
- [Vortex Dynamics Theory](#vortex-dynamics-theory)
- [MATLAB Implementation](#matlab-implementation)
- [Error Handling & Testing](#error-handling--testing)
- [References](#references)

---

## Numerical Methods

### Arakawa Schemes for Advection

**Source:** Arakawa (1966) [1]

**Summary:**
- Arakawa Jacobian schemes conserve energy and enstrophy in 2D vorticity equation
- Three formulations: J1 (energy-conserving), J2 (enstrophy-conserving), J3 (mixed)
- Finite difference implementation uses 9-point stencil
- Essential for long-time integration of vorticity dynamics

**Implementation Notes:**
- Used in `Finite_Difference_Analysis.m` (assumed based on repository name)
- Jacobian computation is core of nonlinear advection term

**Relevance:** Foundation for FD solver accuracy and stability

---

### Poisson Solver for Streamfunction

**Source:** Numerical Recipes (Press et al.) [2]

**Summary:**
- Elliptic equation: ∇²ψ = -ω
- Direct solvers (LU decomposition) vs iterative (Gauss-Seidel, CG)
- MATLAB `\` operator uses sparse LU decomposition
- Periodic boundaries require special treatment (zero-mean constraint)

**Implementation Notes:**
- Streamfunction computed from vorticity via Poisson solve
- Used for velocity field reconstruction: u = ∂ψ/∂y, v = -∂ψ/∂x

**Relevance:** Critical for vorticity-streamfunction formulation

---

### Time Integration

**Source:** LeVeque (2007) [3]

**Summary:**
- Forward Euler explicit time-stepping
- CFL condition: C = u·Δt/Δx must satisfy C < 1 for stability
- Higher-order methods (RK4) provide better accuracy but increase cost
- Viscous term requires additional stability constraint

**Implementation Notes:**
- Analysis.m includes CFL check in config report
- dt parameter specified in Parameters.m

**Relevance:** Stability and accuracy of time evolution

---

### Spectral Methods (FFT-based)

**Source:** Boyd (2001) [4]

**Summary:**
- Spectral accuracy (exponential convergence for smooth solutions)
- Requires periodic boundaries
- FFT-based Poisson solver: ψ̂_k = -ω̂_k / |k|²
- Aliasing errors need dealiasing (2/3 rule)

**Implementation Notes:**
- Spectral_Analysis.m is stub, not fully implemented
- Would require FFT-based Jacobian and Poisson solver

**Relevance:** Future work for high-accuracy simulations

---

### Finite Volume Methods

**Source:** LeVeque (2002) [5]

**Summary:**
- Conservative form of equations
- Flux reconstruction and numerical flux functions (upwinding)
- Well-suited for shocks and discontinuities (not typical in vortex flows)
- Requires careful treatment of source terms

**Implementation Notes:**
- Finite_Volume_Analysis.m is stub, not fully implemented
- Would require flux-based formulation of vorticity equation

**Relevance:** Future work for variable bathymetry and complex geometries

---

### Variable Bathymetry

**Source:** Kutz (PDF reference from user) + similar studies [6]

**Summary:**
- Bathymetry (ocean depth) affects vortex dynamics
- Requires topographic vorticity term in governing equations
- May introduce coordinate stretching or sigma coordinates

**Implementation Notes:**
- Variable_Bathymetry_Analysis.m exists as separate solver
- Framework needs refactoring to treat bathymetry as "environment flag"

**Relevance:** Experimental feature for realistic ocean scenarios

---

## Vortex Dynamics Theory

### Lamb-Oseen Vortex

**Source:** Saffman (1992) [7]

**Summary:**
- Axisymmetric vortex with Gaussian vorticity distribution
- Analytical solution for viscous decay
- ω(r,t) = (Γ₀/4πν(t+t₀)) exp(-r²/4ν(t+t₀))
- Used for code verification

**Implementation Notes:**
- Implemented in `ic_factory.m` as 'Lamb-Oseen' IC type
- Provides exact solution for validation

**Relevance:** Primary test case for solver verification

---

### Gaussian Vortex

**Source:** Standard vortex model

**Summary:**
- Simple Gaussian vorticity distribution
- No exact analytical solution for viscous decay
- Used for testing and pedagogical purposes

**Implementation Notes:**
- Implemented in `ic_factory.m` as 'Gaussian' IC type

**Relevance:** Secondary test case

---

### Multi-Vortex Interactions

**Source:** Aref (1983) [8]

**Summary:**
- Point vortex dynamics and vortex merging
- Chaotic advection in multi-vortex systems
- Merging criteria based on vortex separation and core size

**Implementation Notes:**
- `disperse_vortices.m` provides multi-vortex seeding
- Stability depends on initial separation

**Relevance:** Experimental multi-vortex feature

---

## MATLAB Implementation

### MATLAB uigridlayout Documentation

**Source:** MathWorks Documentation [9]

**Summary:**
- Grid-based layout for UI figures (uifigure)
- Properties: RowHeight, ColumnWidth (fit, 1x, 2x, pixels)
- Layout.Row and Layout.Column for component placement
- Replaces deprecated Position-based layouts

**Implementation Notes:**
- UIController.m uses uigridlayout throughout
- UI_Layout_Config.m centralizes layout parameters
- Developer Mode enables click-to-inspect

**Relevance:** UI architecture and maintainability

---

### MATLAB Error Handling Best Practices

**Source:** MathWorks Best Practices Guide [10]

**Summary:**
- Use MException for structured errors
- error(id, message) with identifier format: 'namespace:component:errorType'
- try/catch blocks for error recovery
- ME.addCause() for cascading errors

**Implementation Notes:**
- ErrorHandler.m implements structured error system
- ErrorRegistry.m defines error code taxonomy
- Identifier format: PREFIX-CATEGORY-NNNN (e.g., RUN-EXEC-0001)

**Relevance:** Debugging and error reporting framework

---

### MATLAB  Unit Testing

**Source:** MathWorks Unit Testing Framework [11]

**Summary:**
- matlab.unittest framework for automated testing
- Test fixtures, setup/teardown
- Assertions and constraints
- CI/CD integration with exit codes

**Implementation Notes:**
- Run_All_Tests.m is omnipotent test harness
- Integrates static analysis + unit + integration tests
- Exit codes: 0 (pass), 1 (fail), 2 (error)

**Relevance:** QA and continuous integration

---

## Error Handling & Testing

### Static Code Analysis

**Source:** MATLAB Code Analyzer (checkcode) [12]

**Summary:**
- Detects code issues, performance problems, and style violations
- checkcode('-id', filename) returns issues with identifiers
- Categories: errors, warnings, info
- Can be automated for CI/CD pipelines

**Implementation Notes:**
- static_analysis.m implements crash-safe per-file analysis
- Maps checkcode IDs to custom error code taxonomy
- Generates JSON and Markdown reports

**Relevance:** Code quality assurance

---

### Error Code Taxonomies

**Source:** Industry best practices [13]

**Summary:**
- Structured error codes improve debugging
- Format: PREFIX-CATEGORY-NUMBER
- Each code has severity, description, remediation
- Centralized error registry for consistency

**Implementation Notes:**
- ErrorRegistry.m defines 30+ error codes
- Categories: SYS-BOOT, CFG-VAL, UI-*, RUN-EXEC, SOL-*, IO-FS, MON-SUS, TST, GEN
- README documents all codes with usage examples

**Relevance:** Consistent error reporting across repository

---

## Useful YouTube Resources

### Finite Difference Methods for PDEs

**Source:** YouTube - "Finite Difference Methods" by Prof. Gilbert Strang [14]

**Summary:**
- MIT OpenCourseWare lecture series
- Covers stability analysis, CFL condition, convergence
- Practical MATLAB examples

**Relevance:** Educational resource for FD implementation

---

### Vorticity-Streamfunction Finite Volume Introduction

**Source:** YouTube - CFD Online [15]

**Summary:**
- Introduction to finite volume methods for vorticity-streamfunction
- Flux reconstruction and numerical flux functions
- Conservative schemes

**Relevance:** Background for FV solver implementation (future work)

---

## References

1. Arakawa A. Computational design for long-term numerical integration of the equations of fluid motion: two-dimensional incompressible flow. Part I. J Comput Phys. 1966;1(1):119-143. doi:10.1016/0021-9991(66)90015-5

2. Press WH, Teukolsky SA, Vetterling WT, Flannery BP. Numerical Recipes: The Art of Scientific Computing. 3rd ed. Cambridge University Press; 2007.

3. LeVeque RJ. Finite Difference Methods for Ordinary and Partial Differential Equations: Steady-State and Time-Dependent Problems. SIAM; 2007.

4. Boyd JP. Chebyshev and Fourier Spectral Methods. 2nd ed. Dover Publications; 2001.

5. LeVeque RJ. Finite Volume Methods for Hyperbolic Problems. Cambridge University Press; 2002.

6. Kutz JN. [PDF Reference - Data-Driven Modeling & Scientific Computation]. University of Washington. [Exact citation pending from user-provided PDF]

7. Saffman PG. Vortex Dynamics. Cambridge University Press; 1992.

8. Aref H. Integrable, chaotic, and turbulent vortex motion in two-dimensional flows. Annu Rev Fluid Mech. 1983;15:345-389. doi:10.1146/annurev.fl.15.010183.002021

9. MathWorks. uigridlayout Properties [Internet]. MATLAB Documentation. Available from: https://www.mathworks.com/help/matlab/ref/matlab.ui.container.gridlayout-properties.html

10. MathWorks. Error Handling Best Practices [Internet]. MATLAB Documentation. Available from: https://www.mathworks.com/help/matlab/error-handling.html

11. MathWorks. matlab.unittest Framework [Internet]. MATLAB Documentation. Available from: https://www.mathworks.com/help/matlab/matlab-unit-test-framework.html

12. MathWorks. checkcode - Check MATLAB Code Files for Problems [Internet]. MATLAB Documentation. Available from: https://www.mathworks.com/help/matlab/ref/checkcode.html

13. RFC 7807. Problem Details for HTTP APIs [adapted for error codes]. IETF; 2016. Available from: https://tools.ietf.org/html/rfc7807

14. Strang G. Computational Science and Engineering [Internet]. MIT OpenCourseWare. Available from: https://ocw.mit.edu/courses/mathematics/

15. CFDOnline. Vorticity-Streamfunction Methods [Internet]. YouTube. [Exact URL pending verification]

---

## Notes on Research Process

**Error Code System Development:**
- Researched industry standards for error taxonomies (RFC 7807, HTTP status codes)
- Adapted PREFIX-CATEGORY-NUMBER format for MATLAB context
- Implemented severity levels (CRITICAL, ERROR, WARN, INFO)
- Each code maps to remediation guidance

**UI Layout Research:**
- Consulted MATLAB uigridlayout documentation extensively
- Learned that Position-based layouts are deprecated in modern MATLAB
- Grid-based layouts provide cross-platform consistency
- Developer Mode (click-to-inspect) inspired by browser devtools

**Test Suite Design:**
- Researched "omnipotent test harness" concept from software engineering best practices
- Integrated static analysis (checkcode), unit tests, integration tests, contract checks
- Deterministic exit codes essential for CI/CD pipelines

**Structured Error Handling:**
- MATLAB MException class provides structured errors
- addCause() allows cascading error context
- Custom ErrorHandler wrapper provides consistent formatting and color-coded output

---

**Maintained by:** MECH0020 Development Team
**Date:** 2026-02-08
