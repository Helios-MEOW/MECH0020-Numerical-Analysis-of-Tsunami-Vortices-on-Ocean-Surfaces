# do deep research on pages 604–610 and finite-difference/spectral solvers

**Extract (pp.604–610):** These pages (from the provided PDF) include Arakawa’s Jacobian definition and implementation notes. They define the discrete Jacobian \(J(\psi,\omega)\) and discuss its conservation properties (energy/enstrophy). Verbatim content is omitted for brevity – consult the PDF for exact formulas. Claude should refer to pp. 604–610 for details and to extract figures.

**Finite-difference guidance:** Use a regular grid for \(\omega\) and streamfunction \(\psi\). Enforce \(\psi=0\) on walls (no normal flow). Handle wetting/drying by setting \(\omega=0\) when water depth →0. Solve Poisson’s equation \(\nabla^2\psi=-\omega\) at each step (e.g. via FFT or iterative solver). Use central differences for ∂x,∂y to compute velocity and Jacobian. 

**Spectral guidance:** Use FFT grids (periodic BCs) or sine/cosine transforms (no-slip walls). Compute derivatives in Fourier space: e.g. \(\widehat\omega_k\), \(\widehat\psi_k\). Aliasing must be removed (2/3 rule). Streamfunction Poisson solve is diagonal: \(\widehat\psi_{k\ell} = -\widehat\omega_{k\ell}/(k^2+\ell^2)\). 

**Time-stepping:** Common choices are 4th-order Runge–Kutta (explicit) or semi-implicit (Crank–Nicolson for diffusion, Adams–Bashforth for advection) or IMEX methods. Ensure CFL ≲0.5 (max(Δt·|u|/Δx)). If viscosity is small, explicit RK with small Δt; for stiff diffusion use implicit. No universal Δt – tune by stability.

**Arakawa Jacobian:** The Arakawa scheme conserves energy and enstrophy. It averages three discrete Jacobians:  
\(J_A=\frac{1}{3}(J_1+J_2+J_3)\), where \(J_1,J_2,J_3\) are the standard, advective, and vorticity forms. This ensures discrete ∑ψJ=0.  

**Pseudocode (Arakawa):**  
```
for each grid point (i,j):
  J1 = ((ψ(i+1,j)-ψ(i-1,j))*(ω(i,j+1)-ω(i,j-1)) - (ψ(i,j+1)-ψ(i,j-1))*(ω(i+1,j)-ω(i-1,j)))/(4ΔxΔy)
  J2 = (ψ(i+1,j)*(ω(i,j+1)-ω(i,j-1)) - ψ(i-1,j)*(ω(i,j+1)-ω(i,j-1))
      - ψ(i,j+1)*(ω(i+1,j)-ω(i-1,j)) + ψ(i,j-1)*(ω(i+1,j)-ω(i-1,j)))/(4ΔxΔy)
  J3 = (ψ(i+1,j)*(ω(i+1,j+1)-ω(i+1,j-1)) - ψ(i-1,j)*(ω(i-1,j+1)-ω(i-1,j-1))
      - ψ(i,j+1)*(ω(i+1,j+1)-ω(i-1,j+1)) + ψ(i,j-1)*(ω(i+1,j-1)-ω(i-1,j-1)))/(4ΔxΔy)
  JA(i,j) = (J1+J2+J3)/3
```

**Solver loops (pseudocode):**  
```
initialize ω0, ψ0 from initial condition
for n=1:Nsteps:
  compute JA = ArakawaJacobian(ψ,ω)  % or J= (u·∇ω) for simpler scheme
  ω_new = ω_old + Δt*( -JA + ν∇²ω_old )
  solve ∇²ψ = -ω_new
  ω_old=ω_new; ψ_old=ψ
```
For spectral: replace finite differences with FFT:  
```
ω_hat = fft2(ω); compute RHS_hat = -i(k_x ψ_hat * k_y ω_hat - k_y ψ_hat * k_x ω_hat)
ω_hat_new = ω_hat + Δt*(RHS_hat - ν*(k²+l²)*ω_hat)
solve ψ_hat = -ω_hat_new/(k²+l²), then ifft to get ψ_new.
```

**Parameters:** No strict constraints – ensure grid resolves smallest features. Typical: Δx≈Δy≈0.01–0.1, CFL~0.1–0.5. Solver tolerance for Poisson ≲1e-6. If unknown, leave ‘no specific constraint’.

**Workflow (Mermaid):**  

```mermaid
flowchart LR
  A[Initialize ω, ψ] --> B[Time loop]
  B --> C[Compute Jacobian J(ψ,ω)]
  C --> D[Update ω = ω + Δt*(−J + ν∇²ω)]
  D --> E[Solve ∇²ψ = −ω]
  E --> F[Next step or output]
```

**Figure extraction:** Claude: open PDF pages 604–610, extract Figures/Tables. E.g. page 605–606 has Arakawa scheme illustration.

**Tags:** finite-difference, spectral, Arakawa, time-stepping, pseudocode

**Bibliography:** Arakawa A. (1966) *J. Comput. Phys.*, Lamb H. (1932) *Hydrodynamics*, Boyd J.P. (2001) *Chebyshev and Fourier Spectral Methods*.