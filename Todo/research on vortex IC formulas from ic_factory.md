# do deep research on vortex IC formulas from ic_factory

**Executive summary:** The repository’s `ic_factory.m` (infrastructure) likely defines analytic vorticity shapes. If the file is inaccessible, we use standard formulas. Key vortices: Gaussian “blob”, vortex pair, multi-blob, Lamb–Oseen, Rankine, Lamb dipole, Taylor–Green, random turbulence, elliptical. Below are code-ready expressions and notes for each.

- **Vortex Blob:** ω(x,y) = (Γ/(2πσ²)) exp(-r²/(2σ²)). Here r²=(x-x0)²+(y-y0)². Scale by Γ, place at (x0,y0). Positive Γ means counterclockwise. Use ~10 grid points across σ, Δt for CFL≈0.1–0.5.  
  *Pseudocode:* `omega = (Gamma/(2*pi*sigma^2))*exp(-((X-x0).^2+(Y-y0).^2)/(2*sigma^2));`

- **Vortex Pair:** Two Gaussians ±Γ separated by distance. ω = ω₁(x,y)+ω₂(x,y) with opposite signs. Place centers (x1,y1),(x2,y2). Ensures zero net circulation.  

- **Multi-Vortex:** Sum of N blobs: ω=Σ Γᵢ/(2πσᵢ²) exp(-|r-rᵢ|²/(2σᵢ²)). Place multiple centers. Good for complex patterns.  

- **Lamb–Oseen:** ω = (Γ/(2πνt)) exp(-r²/(4νt)). Here core grows ∝√(4νt). Use this at t=0 with initial core radius r₀: set νt=r₀²/4. Smooth viscous profile.  

- **Rankine:** ω = Γ/(πa²) if r≤a, else 0. Hard edge at r=a. Γ positive yields CCW. Use many points across a to resolve edge.  

- **Lamb Dipole:** Analytical dipole (Chaplygin–Lamb). In polar coords, ψ ∝ J1(k r)/J0(k a). Harder to code; often omitted or taken from literature.  

- **Taylor–Green:** ψ = A cos(kx) cos(ky); then u = −∂ψ/∂y, v=∂ψ/∂x, ω = ∂v/∂x−∂u/∂y = 2A k sin(kx) sin(ky). Use A amplitude. Good smooth periodic test.  

- **Random turbulence:** Initialize ω̂(k,l) with random phases for a given spectrum, then invert to ω(x,y). Ensures no simple formula.  

- **Elliptical vortex:** ω constant inside an ellipse: ω = Γ/(πab) for points inside ellipse ((x-x0)/a)²+((y-y0)/b)²≤1. Or use rotated ellipse by adjusting coordinates.  

**Comparison table:**  

| IC        | Formula                         | Pros/Cons                       | Uses                      |
|-----------|---------------------------------|---------------------------------|---------------------------|
| Blob      | Gaussian (smooth)               | Smooth, localized; spectral content high | Viscous decay tests, smooth initial eddy |
| Pair      | Two blobs ±Γ                    | Balanced; can test interaction | Vortex merger tests       |
| Multi     | Sum of blobs                    | Complex flow; additive; large dynamic range | Multi-vortex interactions |
| Lamb–Oseen| Gaussian with σ²=4νt            | Physical viscous decay; infinite extent | Diffusion tests, decay of single vortex |
| Rankine   | Constant core, sharp edge       | Non-smooth; Gibbs in spectral | Advection/shock test      |
| Dipole    | Bessel-based analytic (Lamb)    | Self-propelling; known solution | Advection with background flow |
| T–G       | sin×sin waves                   | Exact periodic solution; decays | Spectral and DNS tests    |
| Random    | Random Fourier modes            | Realistic spectrum; stochastic | Turbulence, ensemble tests|
| Elliptical| Constant inside ellipse         | Anisotropic structure            | Rotational test, deformation |

**Mermaid workflow:**  

```mermaid
flowchart LR
  A[Choose IC type] --> B[Compute ω(x,y) formula]
  B --> C[Scale by Γ, shift to (x0,y0)]
  C --> D[Initial Poisson solve ψ]
  D --> E[Enter time-stepping loop]
```

**Tags:** IC-formulas, Lamb-Oseen, Rankine, Taylor-Green, vorticity, init

**Bibliography:** Lamb (1932); Arakawa (1966); Taylor & Green (1937); Pope (2000).