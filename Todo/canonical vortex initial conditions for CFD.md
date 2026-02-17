# do deep research on canonical vortex initial conditions for CFD

**Executive summary:** Common 2D vortex ICs include:  
- **Lamb–Oseen vortex** (Lamb 1932): viscous Gaussian core, with vorticity ω(r)=Γ/(πσ²) exp(−r²/σ²), σ²=4νt【87†L130-L134】.  
- **Rankine vortex** (Rankine 1858): solid-body core, ω=Γ/(πa²) for r≤a, ω=0 for r>a【90†L149-L153】.  
- **Chaplygin–Lamb dipole** (Lamb 1911): a translating vortex pair with known analytic streamfunction.  
- **Taylor–Green vortex** (Taylor & Green 1937): periodic cell flow, ψ∼sin(x)sin(y).  
- **Random turbulence & elliptical vortices**: broadband spectra or Kirchhoff elliptical cores (ω=const inside ellipse).  

**Usage in CFD:** These ICs are widely used to verify vorticity–streamfunction solvers (FDM/FVM/spectral/LBM).  For example, Lamb–Oseen tests viscous diffusion, Rankine/dipole test advection accuracy.  Diagnostics: monitor total circulation ∫ω, enstrophy ∫ω², and PV; compute L1/L2/L∞ errors of ω/ψ.  

**Implementation notes:** Initialize ω(r,θ) from formulas, then solve ∇²ψ=−ω with appropriate boundary ψ.  Use stable schemes (e.g. RK4, Δt respecting CFL≲0.5).  Typical grid: O(100–1000) points across vortex radius.  Solver tolerances ~10⁻⁶ for Poisson.  Wetting/drying: set ω→0 when depth→0.  

**Comparison table (ICs):**  
| Vortex | Form (ω) | Properties | Usage |
|---|---|---|---|
| Lamb–Oseen | Gaussian | Smooth; decays diffusively | Verifies diffusion |
| Rankine | Piecewise | Sharp edge; non-smooth | Tests advection, convergence|
| Lamb dipole | Bessel-like core | Translating vortex | Momentum conservation test |
| Taylor–Green | Sinusoidal | Periodic; decays | DNS/turbulence tests |
| Random | Broadband | Non-coherent | Statistical convergence |
| Elliptical | Const inside ellipse | Anisotropy tests | 

**Pseudocode (sketch):** Initialize ω from formula; loop: advect ω (FDM/FVM stencil or spectral conv), add viscous diffusion, solve ∇²ψ=−ω (FFT or Poisson solver), compute velocity =∇×ψ, update ω, apply boundary/wetting logic.  

**Workflow:** (1) Set IC ω; (2) Compute ψ by Poisson; (3) Time-step ω via advection-diffusion; (4) Iterate/Output.  

**References:** Rankine (1858)【90†L149-L153】; Lamb (1911,1932)【87†L130-L134】; Taylor & Green (1937); Chaplygin (1903).  Cf. CFD verifications (Mao & Sherwin 2009【87†L130-L134】 etc.).  

**Tags:** Lamb-Oseen, Rankine, dipole, Taylor-Green, verification, enstrophy, spectral, LBM.

