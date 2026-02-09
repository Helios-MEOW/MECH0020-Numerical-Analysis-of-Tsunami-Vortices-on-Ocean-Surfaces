# Finite Difference Method

**Status:** ✅ Fully Implemented

## Purpose

Solves 2D incompressible Navier-Stokes equations in vorticity-streamfunction formulation using finite difference spatial discretization and RK4 time integration.

## Physics Solved

- **Vorticity equation:** ∂ω/∂t + u·∇ω = ν∇²ω
- **Poisson equation:** ∇²ψ = -ω
- **Velocity recovery:** u = -∂ψ/∂y, v = ∂ψ/∂x

## Spatial Discretization

- **Method:** 2nd-order finite differences on regular Cartesian grid
- **Advection:** Arakawa 3-point scheme (energy-conserving)
- **Diffusion:** Standard 5-point stencil
- **Boundary:** Periodic (via circshift-based shifts)
- **Poisson solver:** Sparse matrix LU decomposition (MATLAB `\` operator)

## Time Integration

- **Method:** RK4 (4th-order Runge-Kutta)
- **CFL Condition:** dt must satisfy standard explicit stability criterion

## Required Entrypoints

All FD modules MUST provide these three functions:

### `fd_init(cfg, ctx)`

**Purpose:** Initialize FD method state

**Inputs:**
- `cfg` - Configuration struct with fields:
  - `.Nx`, `.Ny` - Grid resolution
  - `.Lx`, `.Ly` - Domain size
  - `.nu` - Viscosity
  - `.dt` - Time step
  - `.ic_type` - Initial condition type
  - `.omega` - Pre-computed omega (optional)

- `ctx` - Context struct (mode-specific data, provided by mode script)

**Outputs:**
- `State` - Initial state struct with fields:
  - `.omega` - Vorticity field (Ny × Nx)
  - `.psi` - Streamfunction field (Ny × Nx)
  - `.t` - Current time (0.0)
  - `.step` - Step counter (0)
  - `.setup` - FD operators and grid data (A matrix, shifts, etc.)

### `fd_step(State, cfg, ctx)`

**Purpose:** Advance solution by one time step using RK4

**Inputs:**
- `State` - Current state (from `fd_init` or previous `fd_step`)
- `cfg` - Configuration (must contain `.dt`, `.nu`)
- `ctx` - Context (unused)

**Outputs:**
- `State` - Updated state with new `.omega`, `.psi`, `.t`, `.step`

**Implementation:** Uses 4-stage RK4 with Arakawa Jacobian for advection term

### `fd_diagnostics(State, cfg, ctx)`

**Purpose:** Compute diagnostic metrics

**Inputs:**
- `State` - Current state
- `cfg`, `ctx` - Configuration and context (unused)

**Outputs:**
- `Metrics` - Struct with:
  - `.max_vorticity` - Max |ω|
  - `.enstrophy` - ∫ ω² dA
  - `.kinetic_energy` - ∫ |∇ψ|² dA
  - `.t` - Current time
  - `.step` - Current step number

## State Fields

The FD `State` struct maintains:

- `omega` - Vorticity field (Ny × Nx)
- `psi` - Streamfunction field (Ny × Nx)
- `t` - Current time
- `step` - Current step number
- `setup` - Persistent operator data:
  - `A` - Poisson solver matrix (sparse)
  - `dx`, `dy`, `delta` - Grid spacing
  - `X`, `Y` - Meshgrid coordinates
  - `shift_xp`, `shift_xm`, `shift_yp`, `shift_ym` - Shift operators for Arakawa scheme

## Capabilities and Assumptions

- ✅ Periodic boundary conditions
- ✅ Square or rectangular domains
- ✅ Constant viscosity
- ✅ All IC types supported (`Lamb-Oseen`, `Gaussian`, etc.)
- ⚠️ Variable bathymetry: experimental (requires separate solver)
- ❌ Non-periodic boundaries: not supported

## Legacy Files

The `legacy_fd/` subdirectory contains the original monolithic FD solver:
- `Finite_Difference_Analysis.m` - Original solver (contains own time loop)
- `FD_Evolution_Mode.m`, etc. - Old mode-per-method files (DEPRECATED)

These files are preserved for reference but SHOULD NOT be used. All new code should use the `fd_init`, `fd_step`, `fd_diagnostics` entrypoints.

## Mathematical Preservation

**IMPORTANT:** The numerical schemes in `fd_init`, `fd_step`, `fd_diagnostics` preserve the EXACT mathematical methods from `Finite_Difference_Analysis.m`:
- Arakawa Jacobian (no changes)
- RK4 time-stepping (no changes)
- Poisson solver (no changes)

Only restructuring/wiring was changed; governing equations and discretizations are IDENTICAL.
