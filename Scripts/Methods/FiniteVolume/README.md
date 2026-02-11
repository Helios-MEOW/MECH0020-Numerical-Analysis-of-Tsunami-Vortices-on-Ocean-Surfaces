# Finite Volume Method (Layered 3D)

**Status:** Experimental (single-file callback module enabled for Evolution)

## Purpose

Provides a finite-volume method path using a structured Cartesian `Nx x Ny x Nz`
layered mesh with:

- periodic boundaries in x/y,
- fixed z boundaries (default no-flux),
- depth-averaged 2D projections for compatibility with existing mode/report flows.

## Current Module Contract

`Scripts/Methods/FiniteVolume/FiniteVolumeMethod.m` is the canonical implementation and exposes:

- `FiniteVolumeMethod('callbacks')`
- `FiniteVolumeMethod('init', cfg, ctx)`
- `FiniteVolumeMethod('step', State, cfg, ctx)`
- `FiniteVolumeMethod('diagnostics', State, cfg, ctx)`
- `FiniteVolumeMethod('run', Parameters)`

The module remains fully self-contained in a single file (no split init/step files).

## 3D Evolution Model (Checkpoint)

- Layered 3D scalar vorticity evolution on structured Cartesian mesh.
- 2D layer-wise Poisson solve for streamfunction recovery.
- Upwinded xy advection + xy diffusion + vertical coupling diffusion.
- Primary state carries 3D fields (`omega3d`, `psi3d`) and projected 2D fields (`omega`, `psi`).

## Dispatcher Support

- `Evolution`: enabled (experimental)
- `Convergence`: blocked for this checkpoint (`SOL-FV-0001`)
- `ParameterSweep`: blocked for this checkpoint (`SOL-FV-0001`)

## Config Fields

Important runtime controls:

- `Parameters.Nz`
- `Parameters.Lz`
- `Parameters.method_config.fv3d.vertical_diffusivity_scale`
- `Parameters.method_config.fv3d.z_boundary`

## References

- LeVeque RJ. *Finite Volume Methods for Hyperbolic Problems*. Cambridge University Press; 2002.
