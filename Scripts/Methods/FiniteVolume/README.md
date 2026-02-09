# Finite Volume Method

**Status:** ⚠️ STUB ONLY - Not Yet Implemented

## Purpose

(Planned) Solves 2D incompressible Navier-Stokes equations in vorticity-streamfunction formulation using finite volume spatial discretization.

## Planned Features

- **Conservative Form:** Flux-based formulation
- **Numerical Flux Functions:** Upwinding for advection
- **Well-Suited For:** Shocks, discontinuities, complex geometries
- **Source Terms:** Careful treatment for vorticity equation

## Current State

All entrypoints are STUBS that throw `SOL-FV-0001` errors:

### `fv_init(cfg, ctx)`
**Status:** Stub - throws error immediately

### `fv_step(State, cfg, ctx)`
**Status:** Stub - throws error immediately

### `fv_diagnostics(State, cfg, ctx)`
**Status:** Stub - throws error immediately

## Implementation Plan

To implement this method:

1. Design flux reconstruction scheme (upwinding, MUSCL, WENO, etc.)
2. Implement numerical flux functions for advection
3. Handle source terms (viscous diffusion)
4. Implement FV Poisson solver (or adapt FD sparse solver)
5. Follow the init/step/diagnostics interface contract

## Required State Fields

(Planned)

- `omega_cells` - Cell-averaged vorticity
- `psi_cells` - Cell-averaged streamfunction
- `fluxes` - Face fluxes (for conservation check)
- `t` - Current time
- `step` - Current step number

## Capabilities (Planned)

- ✅ Variable bathymetry (experimental)
- ✅ Complex geometries
- ✅ Shock-capturing (if needed)
- ⚠️ Periodic boundaries: possible but less natural

## Compatibility

- ⚠️ Variable bathymetry: experimental (requires careful flux reconstruction)
- ❌ Most modes: NOT yet implemented

## Error Codes

When called, FV methods throw:
- **SOL-FV-0001:** "Finite Volume method is not yet implemented. Use FiniteDifference instead."

See `ErrorRegistry.m` for details.

## References

LeVeque RJ. Finite Volume Methods for Hyperbolic Problems. Cambridge University Press; 2002.

## Legacy Files

`Finite_Volume_Analysis.m` in parent directory contains placeholder/experimental code. It is NOT integrated with the new architecture.
