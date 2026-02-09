# Spectral (FFT-based) Method

**Status:** ⚠️ STUB ONLY - Not Yet Implemented

## Purpose

(Planned) Solves 2D incompressible Navier-Stokes equations in vorticity-streamfunction formulation using spectral (FFT-based) spatial discretization.

## Planned Features

- **Spatial Accuracy:** Spectral accuracy (exponential convergence for smooth solutions)
- **Requirements:** Periodic boundaries (intrinsic to FFT)
- **FFT-based Poisson Solver:** ψ̂_k = -ω̂_k / |k|²
- **Aliasing Treatment:** 2/3 dealiasing rule
- **Time Integration:** RK4 or similar explicit method

## Current State

All entrypoints are STUBS that throw `SOL-SP-0001` errors:

### `spectral_init(cfg, ctx)`
**Status:** Stub - throws error immediately

### `spectral_step(State, cfg, ctx)`
**Status:** Stub - throws error immediately

### `spectral_diagnostics(State, cfg, ctx)`
**Status:** Stub - throws error immediately

## Implementation Plan

To implement this method:

1. Create FFT-based Poisson solver
2. Implement spectral derivative operators (in Fourier space)
3. Add dealiasing filter (2/3 rule or similar)
4. Implement FFT-based Jacobian computation
5. Follow the init/step/diagnostics interface contract

## Required State Fields

(Planned)

- `omega_hat` - Vorticity in Fourier space
- `psi_hat` - Streamfunction in Fourier space
- `kx`, `ky` - Wavenumber grids
- `dealias_filter` - 2/3 rule mask
- `t` - Current time
- `step` - Current step number

## Compatibility

- ✅ Periodic boundaries REQUIRED
- ❌ Non-periodic boundaries: NOT compatible
- ❌ Variable bathymetry: NOT compatible

## Error Codes

When called, spectral methods throw:
- **SOL-SP-0001:** "Spectral method is not yet implemented. Use FiniteDifference instead."

See `ErrorRegistry.m` for details.

## References

Boyd JP. Chebyshev and Fourier Spectral Methods. 2nd ed. Dover Publications; 2001.

## Legacy Files

`Spectral_Analysis.m` in this directory contains placeholder/experimental code. It is NOT integrated with the new architecture.
