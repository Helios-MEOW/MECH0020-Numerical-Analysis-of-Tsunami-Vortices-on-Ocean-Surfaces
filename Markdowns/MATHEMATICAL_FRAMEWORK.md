# Mathematical Framework: Finite-Difference Analysis of 2D Vorticity Dynamics

## Overview
This document outlines the mathematical foundations of the finite-difference solver for the 2D incompressible Euler equations with viscous effects. The analysis simulates tsunami vortex evolution on ocean surfaces.

---

## 1. Governing Equations

### 1.1 Vorticity-Streamfunction Formulation

The fundamental equations governing 2D incompressible flow are formulated using vorticity ($\omega$) and streamfunction ($\psi$):

#### Vorticity Evolution Equation
$$\frac{\partial \omega}{\partial t} + \mathbf{u} \cdot \nabla \omega = \nu \nabla^2 \omega$$

Where:
- $\omega(x,y,t) = \frac{\partial v}{\partial x} - \frac{\partial u}{\partial y}$ — scalar vorticity (s⁻¹)
- $\mathbf{u} = (u, v)$ — velocity field (m/s)
- $\nu$ — kinematic viscosity (m²/s)
- $\nabla^2 = \frac{\partial^2}{\partial x^2} + \frac{\partial^2}{\partial y^2}$ — Laplacian operator

**Physical interpretation:** Vorticity evolves due to advection by the flow and dissipation by viscous forces.

#### Streamfunction-Vorticity Relationship (Poisson Equation)
$$\nabla^2 \psi = -\omega$$

Where:
- $\psi(x,y,t)$ — streamfunction (m²/s)
- Velocity components: $u = -\frac{\partial \psi}{\partial y}$, $v = \frac{\partial \psi}{\partial x}$

**Physical interpretation:** The streamfunction provides a non-local inversion of vorticity to velocity. Each vorticity field uniquely determines the velocity field through this elliptic relationship.

**Purpose in analysis:** 
- Reduces the number of unknowns from 3 (u, v, p) to 2 (ω, ψ)
- Automatically satisfies incompressibility ($\nabla \cdot \mathbf{u} = 0$)
- Enables efficient computation of velocity fields from vorticity

---

## 2. Spatial Discretization

### 2.1 Domain and Grid Setup

The computational domain is a rectangular region:
- Horizontal extent: $x \in [-L_x/2, L_x/2]$ (m)
- Vertical extent: $y \in [-L_y/2, L_y/2]$ (m)

**Grid spacing:**
$$\Delta x = \frac{L_x}{N_x - 1}, \quad \Delta y = \frac{L_y}{N_y - 1}$$

Where $N_x$, $N_y$ are the number of grid points in x and y directions.

**Grid resolution:** 
- Total grid points: $N_x \times N_y$
- Total unknowns: $N_x \times N_y$

**Purpose:** Regular Cartesian grid enables use of standard finite-difference stencils and efficient sparse matrix operations.

### 2.2 Periodic Boundary Conditions

All fields ($\omega$ and $\psi$) satisfy **periodic boundary conditions**:
$$\omega(x + L_x, y) = \omega(x, y), \quad \psi(x + L_x, y) = \psi(x, y)$$
$$\omega(x, y + L_y) = \omega(x, y), \quad \psi(x, y + L_y) = \psi(x, y)$$

**Implementation:** Circular shifts using `circshift()` wrap grid indices:
- `shift_xp(A)` ≡ A(:, [2:Nx, 1]) — shift right (East)
- `shift_xm(A)` ≡ A(:, [Nx, 1:Nx-1]) — shift left (West)
- `shift_yp(A)` ≡ A([2:Ny, 1], :) — shift down (North)
- `shift_ym(A)` ≡ A([Ny, 1:Ny-1], :) — shift up (South)

**Purpose:** Periodic BC enables use of the Fast Fourier Transform (FFT) for efficient Poisson solving and avoids boundary layer effects.

### 2.3 Finite-Difference Stencils

#### Discrete Laplacian Operator
At interior points $(i,j)$:
$$\nabla^2_{ij} f = \frac{f_{i+1,j} - 2f_{i,j} + f_{i-1,j}}{(\Delta x)^2} + \frac{f_{i,j+1} - 2f_{i,j} + f_{i,j-1}}{(\Delta y)^2}$$

**Kronecker product form:**
$$A = \frac{1}{(\Delta x)^2} (I_y \otimes T_x) + \frac{1}{(\Delta y)^2} (T_y \otimes I_x)$$

Where:
- $T_x, T_y$ — tridiagonal matrices with periodic boundary conditions
- $I_x, I_y$ — identity matrices
- $\otimes$ — Kronecker product

**Code implementation:** 
```matlab
Tx = spdiags([ones(Nx,1) -2*ones(Nx,1) ones(Nx,1)], [-1 0 1], Nx, Nx);
Tx(1,end) = 1;   % Periodic wrap
Tx(end,1) = 1;   % Periodic wrap
A = kron(Iy, Tx)/dx^2 + kron(Ty, Ix)/dy^2;
```

**Computational cost:** $O(N_x N_y)$ sparse matrix operations

#### Central Difference Velocity Gradients
From streamfunction, velocity components are computed using **centered finite differences**:

$$u_{i,j} = -\frac{\psi_{i,j+1} - \psi_{i,j-1}}{2\Delta y}$$
$$v_{i,j} = \frac{\psi_{i+1,j} - \psi_{i-1,j}}{2\Delta x}$$

**Accuracy:** 2nd order in space

**Code implementation:**
```matlab
u = -(shift_yp(psi) - shift_ym(psi)) / (2*dy);   % -∂ψ/∂y
v = (shift_xp(psi) - shift_xm(psi)) / (2*dx);    % ∂ψ/∂x
```

### 2.4 Poisson Equation Solver

The discrete Poisson equation is:
$$A \psi = -\omega \quad (\text{on periodic domain})$$

**Solution:**
$$\psi = \Delta^2 (A^{-1} \omega)$$

Where $\Delta = \sqrt{(\Delta x)^2 + (\Delta y)^2}$ (characteristic grid spacing).

**Method:** Sparse direct solver (MATLAB `\` operator)
- Uses LU decomposition for sparse matrices
- Computational cost: $O((N_x N_y)^{1.5})$ for typical irregular sparsity patterns
- Efficient on periodic domains with FFT acceleration available

---

## 3. Arakawa Scheme for Advection

### 3.1 The Nonlinear Advection Jacobian

The core nonlinearity in the vorticity equation is the **Jacobian** (advection term):
$$J(\psi, \omega) = \frac{\partial \psi}{\partial x} \frac{\partial \omega}{\partial y} - \frac{\partial \psi}{\partial y} \frac{\partial \omega}{\partial x} = u \omega_y - v \omega_x$$

### 3.2 Arakawa's Three-Point Scheme

The Arakawa scheme evaluates the Jacobian using **three equivalent finite-difference formulations** and averages them to ensure energy conservation properties:

#### Formulation 1 (Centered differences)
$$J_1 = \frac{1}{4\Delta x \Delta y} \left[(\psi_{i+1} - \psi_{i-1})(\omega_j^+ - \omega_j^-) - (\psi_j^+ - \psi_j^-)(\omega_{i+1} - \omega_{i-1})\right]$$

#### Formulation 2 (Metric form)
$$J_2 = \frac{1}{4\Delta x \Delta y} \left[\psi_{i+1}(\omega_{i+1,j+1} - \omega_{i+1,j-1}) - \psi_{i-1}(\omega_{i-1,j+1} - \omega_{i-1,j-1})\right.$$
$$\left. - \psi_{j+1}(\omega_{i+1,j+1} - \omega_{i-1,j+1}) + \psi_{j-1}(\omega_{i+1,j-1} - \omega_{i-1,j-1})\right]$$

#### Formulation 3 (Skew-symmetric form)
$$J_3 = \frac{1}{4\Delta x \Delta y} \left[\psi_{i+1,j+1}(\omega_j^+ - \omega_{i+1}) - \psi_{i-1,j-1}(\omega_{i-1} - \omega_j^-)\right.$$
$$\left. - \psi_{i-1,j+1}(\omega_j^+ - \omega_{i-1}) + \psi_{i+1,j-1}(\omega_{i+1} - \omega_j^-)\right]$$

#### Arakawa Average
$$J_{\text{Arakawa}} = \frac{1}{3}(J_1 + J_2 + J_3)$$

**Code implementation:**
```matlab
J1 = ((psi_ip - psi_im).*(om_jp - om_jm) - (psi_jp - psi_jm).*(om_ip - om_im)) / (4*dx*dy);
J2 = (psi_ip.*(om_ipjp - om_ipjm) - psi_im.*(om_imjp - om_imjm) ...
    - psi_jp.*(om_ipjp - om_imjp) + psi_jm.*(om_ipjm - om_imjm)) / (4*dx*dy);
J3 = (psi_ipjp.*(om_jp - om_ip) - psi_imjm.*(om_im - om_jm) ...
    - psi_imjp.*(om_jp - om_im) + psi_ipjm.*(om_ip - om_jm)) / (4*dx*dy);
J = (J1 + J2 + J3) / 3;
```

**Advantages:**
1. **Energy conservation:** Ensures discrete energy is conserved in inviscid limit
2. **Enstrophy control:** Minimizes spurious enstrophy generation
3. **Stability:** Better stability properties than single-point schemes
4. **Accuracy:** 2nd order in space

**Computational cost:** 3× more operations than simple difference scheme, but critical for physical accuracy.

### 3.3 Discrete Laplacian (Viscous Term)

The viscous dissipation term is:
$$\nu \nabla^2 \omega = \nu \left(\frac{\omega_{i+1} - 2\omega_{i} + \omega_{i-1}}{(\Delta x)^2} + \frac{\omega_{j+1} - 2\omega_{j} + \omega_{j-1}}{(\Delta y)^2}\right)$$

**Purpose:** Represents molecular viscosity, removes small-scale enstrophy, stabilizes numerics

**Coefficient:** Kinematic viscosity $\nu$ (m²/s) — physical parameter controlling dissipation rate

---

## 4. Temporal Integration

### 4.1 Runge-Kutta 4th Order (RK4)

The vorticity evolution is integrated using **Runge-Kutta 4th order** explicit scheme:

#### Time stepping algorithm
Given $\omega^n$ at time $t^n = t + n\Delta t$:

1. **Stage 1:** $k_1 = \Delta t \cdot \text{RHS}(\omega^n)$
2. **Stage 2:** $k_2 = \Delta t \cdot \text{RHS}(\omega^n + \frac{k_1}{2})$
3. **Stage 3:** $k_3 = \Delta t \cdot \text{RHS}(\omega^n + \frac{k_2}{2})$
4. **Stage 4:** $k_4 = \Delta t \cdot \text{RHS}(\omega^n + k_3)$
5. **Update:** $\omega^{n+1} = \omega^n + \frac{\Delta t}{6}(k_1 + 2k_2 + 2k_3 + k_4)$

Where RHS includes both Arakawa and Laplacian terms:
$$\text{RHS}(\omega) = -J(\psi, \omega) + \nu \nabla^2 \omega$$

**Code implementation:**
```matlab
k1 = rhs_fd_arakawa(omega(:), A, dx, dy, nu, shift_xp, shift_xm, shift_yp, shift_ym, Nx, Ny, delta);
k2 = rhs_fd_arakawa(omega(:) + 0.5*dt*k1, A, dx, dy, nu, ...);
k3 = rhs_fd_arakawa(omega(:) + 0.5*dt*k2, A, dx, dy, nu, ...);
k4 = rhs_fd_arakawa(omega(:) + dt*k3, A, dx, dy, nu, ...);
omega(:) = omega(:) + (dt/6) * (k1 + 2*k2 + 2*k3 + k4);
```

**Advantages:**
1. **Accuracy:** 4th order in time
2. **Stability:** Good stability region for parabolic equations with explicit viscous term
3. **Cost:** 4 RHS evaluations per timestep

**Number of RHS evaluations:** $4 \times N_t$ (where $N_t$ is total timesteps)
**Number of Poisson solves:** $4 \times N_t$ (one per RHS evaluation)

### 4.2 CFL Stability Criterion

For explicit time integration of viscous equations, stability requires:

**Advective constraint:**
$$\text{CFL} = \frac{\max(|u|, |v|) \Delta t}{\min(\Delta x, \Delta y)} \lesssim 0.5$$

**Viscous stability:**
$$\nu \frac{\Delta t}{(\Delta x)^2} \lesssim 0.1$$

**Combined:** 
The most restrictive constraint must be satisfied. For vortex-dominated flows, viscous stability typically dominates.

---

## 5. Computational Diagnostics

### 5.1 Enstrophy

**Definition:**
$$E = \frac{1}{2} \int_{\Omega} \omega^2 \, dA$$

**Discrete form:**
$$E = \frac{1}{2} \sum_{i,j} \omega_{i,j}^2 \, \Delta x \Delta y$$

**Physical meaning:** 
- Measures rotational kinetic energy density
- Strictly decreases with viscosity in Navier-Stokes
- Conserved in inviscid limit (Euler)
- Computed at each snapshot time

**Code implementation:**
```matlab
analysis.enstrophy = 0.5 * sum(omega_final(:).^2) * (dx * dy);
```

**Units:** s⁻² (squared angular velocity integrated over area)

### 5.2 Peak Absolute Vorticity

**Definition:**
$$\omega_{\max} = \max_{(x,y)} |\omega(x,y)|$$

**Physical meaning:** 
- Maximum instantaneous rotation rate in the flow
- Indicates vortex strength
- Sensitive to numerical accuracy

**Code implementation:**
```matlab
analysis.peak_abs_omega = max(abs(omega_final(:)));
```

**Units:** s⁻¹ (angular velocity)

### 5.3 Velocity Field Diagnostics

From the streamfunction, velocity components are recovered:

$$u = -\frac{\partial \psi}{\partial y}, \quad v = \frac{\partial \psi}{\partial x}$$

**Discrete form (centered differences):**
$$u_{i,j} = -\frac{\psi_{i,j+1} - \psi_{i,j-1}}{2\Delta y}, \quad v_{i,j} = \frac{\psi_{i+1,j} - \psi_{i-1,j}}{2\Delta x}$$

**Speed magnitude:**
$$|\mathbf{u}| = \sqrt{u^2 + v^2}$$

**Diagnostics extracted:**
- `peak_u`: Maximum horizontal velocity component (m/s)
- `peak_v`: Maximum vertical velocity component (m/s)
- `peak_speed`: Maximum velocity magnitude (m/s)

**Code implementation:**
```matlab
u_final = -(shift_yp(psi_final) - shift_ym(psi_final)) / (2 * dy);
v_final = (shift_xp(psi_final) - shift_xm(psi_final)) / (2 * dx);
speed_final = sqrt(u_final.^2 + v_final.^2);
analysis.peak_u = max(abs(u_final(:)));
analysis.peak_v = max(abs(v_final(:)));
analysis.peak_speed = max(speed_final(:));
```

---

## 6. Initial Conditions

### 6.1 Gaussian Vortex

Standard initial condition: axisymmetric Gaussian vortex

$$\omega(x,y,0) = \Gamma_0 \exp\left(-\frac{r^2}{2\sigma^2}\right)$$

Where:
- $\Gamma_0$ — peak circulation (s⁻¹)
- $\sigma$ — vortex core radius (m)
- $r = \sqrt{x^2 + y^2}$ — distance from domain center

**Physical meaning:** Models a smooth vortex (e.g., mesocyclone, ocean eddy)

### 6.2 Stretched Gaussian Vortex

For multi-vortex or deformed configurations:

$$\omega(x,y,0) = \sum_{k} \Gamma_k \exp\left(-\frac{(x-x_k)^2 + (y-y_k)^2}{2\sigma_k^2}\right)$$

Where each component can have:
- Position: $(x_k, y_k)$
- Circulation: $\Gamma_k$
- Core size: $\sigma_k$

**Implementation:** Controlled via `ic_coeff` parameter structure

---

## 7. Computational Complexity Summary

| Operation | Count | Cost per Op | Total Cost |
|-----------|-------|------------|-----------|
| Poisson solves | $4N_t$ | $O((N_x N_y)^{1.5})$ | $O(4N_t (N_x N_y)^{1.5})$ |
| Arakawa Jacobian | $4N_t$ | $O(N_x N_y)$ | $O(4N_t N_x N_y)$ |
| Laplacian evaluations | $4N_t$ | $O(N_x N_y)$ | $O(4N_t N_x N_y)$ |
| Total grid operations | — | — | Dominated by Poisson |

**Memory requirements:**
- Field storage: $\omega^{n}, \psi^{n}$ — $2 N_x N_y$ reals
- Snapshots: $\omega^{\text{snap}}, \psi^{\text{snap}}$ — $2N_x N_y N_{\text{snap}}$ reals
- Matrix A: $\sim 5 N_x N_y$ nonzeros (pentadiagonal structure)

---

## 8. References and Physical Context

### Governing Equations
- **2D Navier-Stokes:** Incompressible viscous fluid dynamics
- **Vorticity-Streamfunction formulation:** Reduces 3 variables (u, v, p) to 2 (ω, ψ)

### Numerical Methods
- **Arakawa scheme:** Arakawa, A. (1966) — Conservative Jacobian approximation
- **RK4 integration:** 4th-order explicit Runge-Kutta method
- **Periodic BC:** Enables spectral-like accuracy on Cartesian grids

### Physical Phenomena Modeled
- **Vortex stretching/tilting:** Nonlinear Jacobian term
- **Viscous dissipation:** Laplacian term with kinematic viscosity
- **Vortex dynamics:** Self-induced motion through streamfunction inversion

---

## 9. Code-to-Mathematics Mapping

| Mathematics | MATLAB Function | Key Variables |
|-------------|-----------------|---|
| $\frac{\partial \omega}{\partial t} + \mathbf{u} \cdot \nabla \omega = \nu \nabla^2 \omega$ | `rhs_fd_arakawa()` | `dwdt`, `J`, `lap_omega` |
| $\nabla^2 \psi = -\omega$ | `A \ omega(:)` | `A` (Poisson matrix), `psi_vec` |
| $u = -\partial \psi / \partial y, v = \partial \psi / \partial x$ | Lines 303-304 | `u`, `v`, `shift_yp`, `shift_xp` |
| Arakawa average | Lines 597-606 | `J1`, `J2`, `J3`, `J` |
| RK4 update | Lines 124-127 | `k1`, `k2`, `k3`, `k4` |
| Enstrophy | Line 195 | `analysis.enstrophy` |
| Velocity diagnostics | Lines 197-206 | `peak_u`, `peak_v`, `peak_speed` |


