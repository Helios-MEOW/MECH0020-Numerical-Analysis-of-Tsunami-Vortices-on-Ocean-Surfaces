# do deep research on finite-difference/spectral solvers and Arakawa Jacobian

**Extracts (pp.604–610 & Sect.9):** These pages define the Arakawa Jacobian and discuss finite-difference vs spectral methods (streamfunction–vorticity).  Verbatim text is not reproduced here; consult the PDF for exact formulas. 

**Finite-difference guidance:** Use a uniform grid with central differences. Boundary: set streamfunction ψ=0 on walls (no normal flow). Wetting/drying: enforce ω=0 where water depth=0. Solve Poisson ∇²ψ=−ω each timestep (e.g. with Gauss–Seidel or FFT if homogeneous BCs). Compute Jacobian J = u·∇ω via Arakawa’s 3-point formula for conservation (see below). 

**Spectral guidance:** Use FFT (periodic) or sine/cosine transforms (walls). Compute derivatives in k-space: e.g. \(\hat\omega_{kℓ}\) → \(\hat\psi_{kℓ} = -\hat\omega_{kℓ}/(k^2+ℓ^2)\). Apply 2/3-dealiasing on nonlinear terms. Streamfunction Poisson solve is diagonal in spectral domain. 

**Time-stepping:** Common schemes: RK4 (explicit), Adams–Bashforth, or semi-implicit Crank–Nicolson/Adams (IMEX) for stiff terms. Ensure CFL ≤0.5 (use max(|u|Δt/Δx)). If viscosity small, use small Δt or implicit diffusion. No fixed Δt—adjust by stability. 

**Arakawa Jacobian:** A discrete Jacobian conserving energy & enstrophy. Define three forms J1,J2,J3 (see Arakawa 1966) and average: J_A = (J1+J2+J3)/3. Conservation: ∑ ψ J_A =0, ∑ ω J_A =0. 

**Arakawa pseudocode (i,j grid):**  
```
for each i,j:
  J1 = ((ψ[i+1,j]-ψ[i-1,j])*(ω[i,j+1]-ω[i,j-1])
       - (ψ[i,j+1]-ψ[i,j-1])*(ω[i+1,j]-ω[i-1,j]))/(4ΔxΔy)
  J2 = (ψ[i+1,j]*(ω[i,j+1]-ω[i,j-1]) - ψ[i-1,j]*(ω[i,j+1]-ω[i,j-1])
       - ψ[i,j+1]*(ω[i+1,j]-ω[i-1,j]) + ψ[i,j-1]*(ω[i+1,j]-ω[i-1,j]))/(4ΔxΔy)
  J3 = (ψ[i+1,j]*(ω[i+1,j+1]-ω[i+1,j-1]) - ψ[i-1,j]*(ω[i-1,j+1]-ω[i-1,j-1])
       - ψ[i,j+1]*(ω[i+1,j+1]-ω[i-1,j+1]) + ψ[i,j-1]*(ω[i+1,j-1]-ω[i-1,j-1]))/(4ΔxΔy)
  JA = (J1+J2+J3)/3
  J[i,j] = JA
```

**Solver loops:**  

*FDM loop:*  
```
initialize ω, ψ (ICs)
for n=1:Nsteps:
  compute J = ArakawaJacobian(ψ,ω)
  ω_new = ω + Δt*(-J + ν∇²ω)
  solve ∇²ψ = -ω_new
  ω = ω_new
```

*Spectral loop:*  
```
ω̂ = fft2(ω); ψ̂ = fft2(ψ)
for n=1:Nsteps:
  compute convective term: Ĉ = -ikx ψ̂ * ky ω̂ + iky ψ̂ * kx ω̂ (dealiased)
  ω̂_new = ω̂ + Δt*(Ĉ - ν(kx^2+ky^2)ω̂)
  ψ̂ = -ω̂_new/(kx^2+ky^2)  (set ψ̂[k=0]=0)
  ω̂ = ω̂_new
end
```

**Parameters:** Typical Δx≈Δy small enough to resolve flow (e.g. grid>=100²); Δt such that max(|u|Δt/Δx)<0.5. Poisson solver tol≲1e-6. (If unknown, “no specific constraint.”)  

**Figure extraction:** Claude: open PDF on pages 604–610. Extract any figures of Jacobian scheme or spectra (e.g. if Fig.9.1 on p.605). Crop around the boxed formulae as needed, ensuring legibility.  

```mermaid
flowchart LR
  A[Init ω,ψ] --> B[Loop]
  B --> C[Compute J(ψ,ω)]
  C --> D[Update ω via time-step]
  D --> E[Poisson solve ψ]
  E --> F[Next step/output]
```

**Tags:** finite-difference, spectral, Arakawa, RK4, IMEX, pseudocode

**References:** Arakawa A. (1966); Boyd J.P. (2001); Lamb H. (1932).