# Spectral (FFT-based) Method

**Status:** Experimental (single-file callback module enabled)

## Purpose

Solves 2D incompressible Navier-Stokes equations in vorticity-streamfunction form
using FFT-based spatial discretization and RK4 time integration in Fourier space.

## Current Module Contract

`Scripts/Methods/Spectral/SpectralMethod.m` is the canonical implementation and exposes:

- `SpectralMethod('callbacks')`
- `SpectralMethod('init', cfg, ctx)`
- `SpectralMethod('step', State, cfg, ctx)`
- `SpectralMethod('diagnostics', State, cfg, ctx)`
- `SpectralMethod('run', Parameters)`

The module keeps all method internals in one file, matching the FD architecture.

## Frequency-Domain Controls

The method supports explicit frequency-grid control through:

- `cfg.kx`
- `cfg.ky`

If omitted, `kx/ky` are derived from `Nx/Ny` and domain lengths.

## Dispatcher Support

- `Evolution`: enabled (experimental)
- `Convergence`: enabled (experimental), including explicit `kx/ky` refinement levels
- `ParameterSweep`: blocked in dispatcher for this checkpoint (`SOL-SP-0001`)

## Compatibility

- Periodic boundaries in x/y are required by the FFT formulation.
- Variable bathymetry is not part of this spectral checkpoint.

## References

- Boyd JP. *Chebyshev and Fourier Spectral Methods*. 2nd ed. Dover; 2001.
- Kutz JN. *Data-Driven Modeling & Scientific Computation* (spectral section used for convergence workflow design).
