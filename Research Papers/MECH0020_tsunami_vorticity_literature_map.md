# MECH0020 Tsunami Vorticity Numerical Study — Literature Map and Source Summaries

**Author:** Helios  
**Date:** 11 Feb 2026  
**Generated from:** `MECH0020 10-02-2026, 23-05-58.csv` + `Links.txt`


## Table of Contents
- [Introduction](#introduction)
- [Core Governing Equations](#core-governing-equations)
- [Method Taxonomy and Themes](#method-taxonomy-and-themes)
- [Reference Index](#reference-index)
- [Per-Source Summaries and Extraction Checklist](#per-source-summaries-and-extraction-checklist)
- [Bibliography (Vancouver, numeric)](#bibliography-vancouver-numeric)

## Introduction
This document consolidates the sources listed in your Zotero-style CSV export and your standalone links file. It provides a method/theme taxonomy, an index of sources, and a per-source extraction checklist aimed at building a tsunami-vorticity numerical study (e.g., SWE / vorticity–streamfunction / advection–diffusion, plus modern solvers like LBM and SPH).

Only sources for which accessible text was available in the provided material have filled-in technical summaries. For the remaining entries, the sections are structured to support deterministic extraction by a separate agent (e.g., Codex) once PDFs/full texts are available.

## Core Governing Equations
This section provides reference equations commonly used across the literature; individual sources may adopt variants, add source terms, or use alternative variables.

### Nonlinear Shallow-Water Equations

```latex
\begin{align}
\frac{\partial h}{\partial 
t} + \nabla\cdot\left(h\mathbf{u}\right) &= 0
\\
\frac{\partial \left(h\mathbf{u}\right)}{\partial t} + \nabla\cdot\left(h\mathbf{u}\otimes\mathbf{u}\right) + \frac{g}{2}\nabla\left(h^2\right) &= -g h \nabla z_b + \mathbf{S}
\end{align}
```

### 2D Vorticity and Streamfunction

```latex
\begin{align}
\omega &= \frac{\partial v}{\partial x} - \frac{\partial u}{\partial y}
\\
\nabla^2\psi &= -\omega
\\
u &= \frac{\partial \psi}{\partial y}
\\
v &= -\frac{\partial \psi}{\partial x}
\end{align}
```

### Advection–Diffusion (Generic)

```latex
\begin{align}
\frac{\partial \phi}{\partial t} + \mathbf{u}\cdot\nabla \phi &= \kappa \nabla^2 \phi + q
\end{align}
```


## Method Taxonomy and Themes

```mermaid
flowchart TD
  A[Tsunami / Vorticity Simulation] --> B[PDE-based\n(SWE, NS, Boussinesq)]
  A --> C[Meso / Particle\n(LBM, SPH, MPS, MPM)]
  B --> D[FDM / FVM\n(upwind, Godunov)]
  B --> E[FEM / DG\n(unstructured)]
  B --> F[Spectral\n(Fourier/Chebyshev)]
  C --> G[LBM\n(BGK, MRT, LES)]
  C --> H[SPH / DEM\n(FSI, breaking)]
```

### Tag Glossary
Tags are derived heuristically from titles/venues/DOIs/URLs and should be treated as triage aids.


## Reference Index

| Key | Title | Tags |
|---|---|---|
| Key | Title | Tags |
| Key | Title | Tags |
| JWXS82ZL | Computational Fluid Dynamics: Shallow water modeling | shallow-water |
| G3JFAXU5 | Three-Dimensional Modeling of Tsunami Waves Triggered by Submarine Landslides Based on the Smoothed Particle Hydrodynamics Method | tsunami, sph |
| IMUXYWYY | Impact of vorticity and viscosity on the hydrodynamic evolution of hot QCD medium | vorticity |
| GCKETLYT | Numerical Study on the Turbulent Structure of Tsunami Bottom Boundary Layer Using the 2011 Tohoku Tsunami Waveform | tsunami, bathymetry |
| J5YRQG9F | Hydrodynamic aspects of tsunami wave motion: a review | tsunami |
| 2NZ5V2PP | Modelling of vorticity, sound and their interaction in two-dimensional superfluids | vorticity |
| 8X5DYCWZ | Vortex suppression of tsunami-like waves by underwater barriers | tsunami |
| VRFNVX3Q | Numerical Analysis of Hydrodynamics Around Submarine Pipeline End Manifold (PLEM) Under Tsunami-Like Wave | tsunami, turbulence |
| BWGUR9ZS | Weak vorticity formulation of 2D Euler equations with white noise initial condition | vorticity |
| 82Q7PID8 | Laboratory study on protection of tsunamiinduced scour by offshore breakwaters | tsunami |
| 7399AG22 | Streamfunction-Vorticity Formulation | vorticity, turbulence, vortex-method |
| PBKH3IHV | Tsunami numerical modeling and mitigation | tsunami |
| QE98MWU5 | Lecture 8: The Shallow-Water Equations | shallow-water |
| KJDHHVX8 | Vorticity dynamics and sound generation in two-dimensional fluid flow Articles You May Be Interested In Validation of a hybrid method of aeroacoustic noise computation applied to internal flows Vorticity dynamics and sound generation in two-dimensional fluid flow | vorticity, turbulence, benchmark |
| MGYMW9BK | First vorticity–velocity–pressure numerical scheme for the Stokes problem | vorticity, navier-stokes |
| E29RAUWV | Vorticity Boundary Condition and Related Issues for Finite Difference Schemes | vorticity, finite-difference |
| 3KIJF5LM | 16: Stream function, vorticity equations | vorticity |
| 3WBCRWBQ | On the modelling of tsunami generation and tsunami inundation | tsunami, runup |
| 497YHWAY | Numerical Techniques for the Shallow Water Equations | shallow-water |
| 5TWQDCNB | SIMPLE FINITE ELEMENT METHOD IN VORTICITY FORMULATION FOR INCOMPRESSIBLE FLOWS | vorticity, finite-element, navier-stokes |
| 7T6CERE7 | On the stream function‐vorticity finite element solutions of Navier‐Stokes equations | vorticity, finite-element, navier-stokes |
| 83SXQR9F | Shallow water equations for equatorial tsunami waves | tsunami, shallow-water, turbulence |
| 8UH9AZC2 | NUMERICAL METHODS FOR SHALLOW-WATER FLOW | shallow-water |
| C4HF4T4R | A numerical study of the MRT-LBM for the shallow water equation in high Reynolds number flows: An application to real-world tsunami simulation | tsunami, shallow-water, lbm |
| CEM7Z75L | Numerical techniques for the shallow water equations | shallow-water |
| DJKB9NDL | The shallow water wave equation and tsunami propagation | tsunami, shallow-water |
| J7NR9DLP | Numerical study on the hydrodynamic characteristics of submarine pipelines under the impact of real-world tsunami-like waves | tsunami |
| LNK021 | a-new-method-for-the-numerical-solution-of-vorticity-streamfuncti | vorticity |
| LNK036 | Vorticity-dynamics-and-sound-generation-in-two | vorticity |
| LNK038 | \#:\textasciitilde{}:text=Abstract,a\%20general\%20distributed\%20vorticity\%20field. | vorticity |
| LNK039 | 128\_1\_online | vorticity, lbm |
| LNK040 | 271519995\_RBF-Vortex\_Methods\_for\_the\_Barotropic\_Vorticity\_Equation\_on\_a\_Sphere | vorticity, sph |
| LNK045 | vortices-over-bathymetry | tsunami, bathymetry |
| LNK048 | 1-s2.0-S2590037423000663-main | tsunami |
| LNK055 | scholar\_lookup | tsunami |
| M5PIAXWZ | Numerical study on the turbulent structure of tsunami bottom boundary layer using the 2011 tohoku tsunami waveform | tsunami, bathymetry |
| QNI2R5I3 | Advanced numerical modelling of tsunami wave propagation, transformation and run-up | tsunami, turbulence, runup |
| QQ2E4TQN | Numerical methods for the nonlinear shallow water equations | shallow-water |
| RVKLA57C | Numerical investigation of tsunami wave impacts on different coastal bridge decks using immersed boundary method | tsunami |
| UA3DUAEL | Vorticity dynamics | vorticity |
| UC6L8ZHR | Large eddy simulation modeling of tsunami-like solitary wave processes over fringing reefs | tsunami |
| V62NTNUQ | Numerical investigation of tsunami-like wave hydrodynamic characteristics and its comparison with solitary wave | tsunami |
| YDE8HA5L | Shallow-water approximation | shallow-water |
| ZSHYNA2A | Numerical simulation of tsunami-scale wave boundary layers | tsunami |
| EWEW2MVE | Long-wave Runup Models | runup |
| SLJX7XUP | Modeling Spatio‐Temporal Transport: From Rigid Advection to Realistic Dynamics | turbulence |
| 3CHK5UFJ | Unsteady aerodynamic loads on pitching aerofoils represented by Gaussian body force distributions | unclassified |
| LVCKSYWR | Metrics and evaluations for computational and sustainable AI efficiency | unclassified |
| RZB96MSQ | Metrics for Computational and Sustainable AI Efficiency | unclassified |
| VH4XV5BU | Measuring Software Energy for a Sustainable Future: A Practical Guide | unclassified |
| 3K5JVPCF | Analysis of wind turbine wake dynamics by a gaussian-core vortex lattice technique | unclassified |
| 6RYI78TN | Numerical modelling of advection diffusion equation using Chebyshev spectral collocation method and Laplace transform | spectral, advection-diffusion, turbulence |
| F9FMHPDS | Vortices over bathymetry | bathymetry |
| IACZM64D | Effect of the kinematic viscosity on liquid flow hydrodynamics in vortex mixers | unclassified |
| 523LRD46 | A spatial local method for solving 2D and 3D advection-diffusion equations | advection-diffusion |
| 5A3F6Y87 | Viscous merging of three vortices | unclassified |
| H4QX69B3 | GREENER principles for environmentally sustainable computational science | turbulence |
| WACZVN59 | A maximum principle of the Fourier spectral method for diffusion equations | spectral |
| 3QYM282P | Spectral3 | spectral |
| 666FZA93 | FD 1 | unclassified |
| 76VUM9IN | overcoming | unclassified |
| N2UTNRTT | Spectral1 | spectral |
| DWRAZZH6 | Spectral analysis and computation of effective diffusivities in space-time periodic incompressible flows | spectral, navier-stokes |
| 8A4U9P4H | Interaction of multiple vortices over a double delta wing | unclassified |
| 5WBTXBH4 | Post-print archive | unclassified |
| VBW4M665 | A coupled lattice Boltzmann and finite volume method for natural convection simulation | finite-volume, lbm, turbulence |
| TRSV998T | A Lattice-Boltzmann solver for 3D fluid simulation on GPU | unclassified |
| S5PU436G | Modelling vortex-vortex and vortex-boundary interaction | unclassified |
| CHKSLDH3 | LATTICE BOLTZMANN METHOD FOR FLUID FLOWS | lbm |
| 3WG8ASE2 | Quantitative experimental and numerical investigation of a vortex ring impinging on a wall | unclassified |
| 2UXAPQTH | EQUATIONS OF FLUID MECHANICS | unclassified |
| 48U93KZ8 | Numerical Solution of the Advection-Diffusion Equation using the Discontinuous Enrichment Method (DEM) | sph, advection-diffusion |
| FTVDGCVQ | Chapter 3 | unclassified |
| FWNDDZNQ | Numerical Solution of Advection-Diffusion-Reaction Equations | advection-diffusion |
| GXH7LEHG | Reviewer | unclassified |
| L255D6QK | overcoming | unclassified |
| LNK001 | 1161283 | unclassified |
| LNK002 | S2590037423000663 | unclassified |
| LNK003 | ssostart | unclassified |
| LNK004 | S2590037423000663 | unclassified |
| LNK005 | 350875965\_A\_spatial\_local\_method\_for\_solving\_2D\_and\_3D\_advection-diffusion\_equations | advection-diffusion |
| LNK006 | 66bdd115ac105ea17af303e73d4fec449754-v448bk | turbulence |
| LNK007 | 2404.18754 | unclassified |
| LNK008 | melosh08\_kalashnikova | unclassified |
| LNK009 | order | unclassified |
| LNK010 | 144012989 | turbulence |
| LNK011 | 7801 | unclassified |
| LNK012 | 1 | unclassified |
| LNK013 | 144012989 | turbulence |
| LNK014 | 080704\_TCs\_Part\_II\_Chapter01 | unclassified |
| LNK015 | 1 | unclassified |
| LNK016 | S0045782508002855 | unclassified |
| LNK017 | S0045782508002855 | unclassified |
| LNK018 | authorization.oauth2 | unclassified |
| LNK019 | deliverInstCredentials | unclassified |
| LNK020 | S0263876224002363 | unclassified |
| LNK022 | Lecture05 | finite-element |
| LNK023 | premium-announcement | unclassified |
| LNK024 | 2506.05081 | unclassified |
| LNK025 | item | unclassified |
| LNK026 | introduction-to-ansys-apdl-programming-easy-hand-on-bar-example-of-learning-apdl-8f584e1be5f7 | unclassified |
| LNK027 | ansys-apdl-code-example | unclassified |
| LNK028 | S1569190X1200038X | unclassified |
| LNK029 | S0017931013010417 | unclassified |
| LNK030 | books | unclassified |
| LNK031 | annurev.fluid.30.1.329 | unclassified |
| LNK032 | S0029549323000080 | unclassified |
| LNK033 | pdf | unclassified |
| LNK034 | S1270963815003648 | unclassified |
| LNK035 | S1270963815003648 | unclassified |
| LNK037 | 19222 | unclassified |
| LNK041 | chapter3 | unclassified |
| LNK042 | 1328flan | unclassified |
| LNK043 | Dam2023\_Viscous\_merging\_3\_vort | turbulence |
| LNK044 | chpthree.PDF | unclassified |
| LNK046 | E2BD59CDE6BA9052BED8FF9B20A71025 | bathymetry |
| LNK047 | A-spatial-local-method-for-solving-2D-and-3D-advection-diffusion-equations | advection-diffusion |
| LNK049 | S2590037423000663 | unclassified |
| LNK050 | era-31-09-273 | unclassified |
| LNK051 | S0263876224002363 | unclassified |
| LNK052 | S2590037423000663 | finite-volume |
| LNK053 | S1569190X1200038X | unclassified |
| LNK054 | S0017931013010417 | unclassified |
| LNK056 | S0029549323000080\#sec2 | unclassified |
| LNK057 | endnote.com | unclassified |
| LNK058 | free-trial | unclassified |
| LNK059 | s43588-023-00461-y | turbulence |
| LNK060 | 2510.17885 | unclassified |
| LNK061 | cfd5 | unclassified |
| SG9B7EWZ | https://www.researchgate.net/publication/352160233\_Analytical\_Effects\_of\_Torsion\_on\_Timber\_Beams | unclassified |


## Per-Source Summaries and Extraction Checklist

### Computational Fluid Dynamics: Shallow water modeling

- **Key:** `JWXS82ZL`  
- **Cite:** [1]  
- **URL/DOI:** https://www.mighte.org/computational-fluid-dynamics-shallow-water-modeling.html  
- **Tags:** shallow-water  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Three-Dimensional Modeling of Tsunami Waves Triggered by Submarine Landslides Based on the Smoothed Particle Hydrodynamics Method

- **Key:** `G3JFAXU5`  
- **Cite:** [2]  
- **URL/DOI:** DOI: 10.3390/jmse11102015  
- **Tags:** tsunami, sph  
- **Access status:** MDPI page provides full text open access.  

**Summary:** Presents a 3D smoothed particle hydrodynamics (SPH) model for tsunami generation by submarine landslides. Validates against underwater landslide model tests and applies the model to the Baiyun landslide (South China Sea), extracting slide kinematics (velocity/runout) and predicting generated tsunami waves. Reports sensitivity results: tsunami amplitude increases with landslide volume and decreases with water depth.

**Equations / models to extract:** Equations not extracted from the landing page; obtain PDF and extract governing/discretized equations directly.

**Computational process to extract:** Extracted from accessible landing-page abstract/highlights; full computational details require PDF text parsing.

**Figures to capture (Codex instructions):** MDPI page references multiple figures (e.g., particle velocity fields and 3D terrain propagation). Capture: experiment geometry, validation comparisons, Baiyun landslide simulation snapshots, and amplitude-vs-parameter curves.

---

### Impact of vorticity and viscosity on the hydrodynamic evolution of hot QCD medium

- **Key:** `IMUXYWYY`  
- **Cite:** [3]  
- **URL/DOI:** DOI: 10.1140/epjc/s10052-023-12027-3  
- **Tags:** vorticity  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Numerical Study on the Turbulent Structure of Tsunami Bottom Boundary Layer Using the 2011 Tohoku Tsunami Waveform

- **Key:** `GCKETLYT`  
- **Cite:** [4]  
- **URL/DOI:** DOI: 10.3390/jmse10020173  
- **Tags:** tsunami, bathymetry  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Hydrodynamic aspects of tsunami wave motion: a review

- **Key:** `J5YRQG9F`  
- **Cite:** [5]  
- **URL/DOI:** https://www.researchgate.net/publication/350821621\_Hydrodynamic\_aspects\_of\_tsunami\_wave\_motion\_a\_review  
- **Tags:** tsunami  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Modelling of vorticity, sound and their interaction in two-dimensional superfluids

- **Key:** `2NZ5V2PP`  
- **Cite:** [6]  
- **URL/DOI:** DOI: 10.1088/1367-2630/ab1bb5  
- **Tags:** vorticity  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Vortex suppression of tsunami-like waves by underwater barriers

- **Key:** `8X5DYCWZ`  
- **Cite:** [7]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S0029801819302380  
- **Tags:** tsunami  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Numerical Analysis of Hydrodynamics Around Submarine Pipeline End Manifold (PLEM) Under Tsunami-Like Wave

- **Key:** `VRFNVX3Q`  
- **Cite:** [8]  
- **URL/DOI:** https://diving-rov-specialists.com/index\_htm\_files/os-250-numerical-analysis-hydrodynamics-around-submarine-pipeline-end-manifold.pdf  
- **Tags:** tsunami, turbulence  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Weak vorticity formulation of 2D Euler equations with white noise initial condition

- **Key:** `BWGUR9ZS`  
- **Cite:** [9]  
- **URL/DOI:** DOI: 10.1080/03605302.2018.1467448  
- **Tags:** vorticity  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Laboratory study on protection of tsunamiinduced scour by offshore breakwaters

- **Key:** `82Q7PID8`  
- **Cite:** [10]  
- **URL/DOI:** DOI: 10.1007/s110690152131x  
- **Tags:** tsunami  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Streamfunction-Vorticity Formulation

- **Key:** `7399AG22`  
- **Cite:** [11]  
- **URL/DOI:** https://old.iist.ac.in/sites/default/files/people/psi-omega.pdf  
- **Tags:** vorticity, turbulence, vortex-method  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Tsunami numerical modeling and mitigation

- **Key:** `PBKH3IHV`  
- **Cite:** [12]  
- **URL/DOI:** DOI: 10.3221/igf-esis.12.06  
- **Tags:** tsunami  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Lecture 8: The Shallow-Water Equations

- **Key:** `QE98MWU5`  
- **Cite:** [13]  
- **URL/DOI:** https://gfd.whoi.edu/wp-content/uploads/sites/18/2018/03/lecture8-harvey\_136564.pdf  
- **Tags:** shallow-water  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Vorticity dynamics and sound generation in two-dimensional fluid flow Articles You May Be Interested In Validation of a hybrid method of aeroacoustic noise computation applied to internal flows Vorticity dynamics and sound generation in two-dimensional fluid flow

- **Key:** `KJDHHVX8`  
- **Cite:** [14]  
- **Tags:** vorticity, turbulence, benchmark  
- **Access status:** unknown  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### First vorticity–velocity–pressure numerical scheme for the Stokes problem

- **Key:** `MGYMW9BK`  
- **Cite:** [15]  
- **URL/DOI:** https://linkinghub.elsevier.com/retrieve/pii/S0045782503003773  
- **Tags:** vorticity, navier-stokes  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Vorticity Boundary Condition and Related Issues for Finite Difference Schemes

- **Key:** `E29RAUWV`  
- **Cite:** [16]  
- **URL/DOI:** DOI: 10.1006/jcph.1996.0066  
- **Tags:** vorticity, finite-difference  
- **Access status:** ScienceDirect page indicates open archive / Creative Commons.  

**Summary:** Discusses three issues in finite-difference schemes for unsteady viscous incompressible flows in vorticity form: vorticity boundary conditions, efficient time-stepping, and equivalence to velocity--pressure formulations. Shows that several global vorticity boundary conditions can be written as local formulas; reports that centered differences coupled with 3rd/4th-order explicit Runge--Kutta avoid cell-Reynolds-number constraints and are stable under a convective CFL condition for high Reynolds number flows; and demonstrates an equivalence between the classical MAC scheme and Thom's vorticity formula (in an appropriate discrete sense), enabling an efficient 4th-order Runge--Kutta time discretization for the MAC scheme.

**Equations / models to extract:** Equations not extracted from the landing page; obtain PDF and extract governing/discretized equations directly.

**Computational process to extract:** Extracted from accessible landing-page abstract/highlights; full computational details require PDF text parsing.

**Figures to capture (Codex instructions):** If you obtain the PDF, capture: (i) any schematic comparing boundary-condition formulations; (ii) stability/accuracy tables for RK vs alternatives.

---

### 16: Stream function, vorticity equations

- **Key:** `3KIJF5LM`  
- **Cite:** [17]  
- **URL/DOI:** https://math.libretexts.org/Bookshelves/Scientific\_Computing\_Simulations\_and\_Modeling/Scientific\_Computing\_(Chasnov)/III\%3A\_Computational\_Fluid\_Dynamics/16\%3A\_Stream\_Function\_Vorticity\_Equations  
- **Tags:** vorticity  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### On the modelling of tsunami generation and tsunami inundation

- **Key:** `3WBCRWBQ`  
- **Cite:** [18]  
- **URL/DOI:** DOI: 10.1016/j.piutam.2014.01.029  
- **Tags:** tsunami, runup  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Numerical Techniques for the Shallow Water Equations

- **Key:** `497YHWAY`  
- **Cite:** [19]  
- **URL/DOI:** https://www.reading.ac.uk/maths-and-stats/-/media/project/uor-main/schools-departments/maths/documents/0299pdf.pdf?la=en\&hash=10B5729D689DDBF51BFDF0F9C6AA3C82  
- **Tags:** shallow-water  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### SIMPLE FINITE ELEMENT METHOD IN VORTICITY FORMULATION FOR INCOMPRESSIBLE FLOWS

- **Key:** `5TWQDCNB`  
- **Cite:** [20]  
- **URL/DOI:** https://web.math.princeton.edu/\textasciitilde{weinan/papers/cfd9.pdf  
- **Tags:** vorticity, finite-element, navier-stokes  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### On the stream function‐vorticity finite element solutions of Navier‐Stokes equations

- **Key:** `7T6CERE7`  
- **Cite:** [21]  
- **URL/DOI:** DOI: 10.1002/nme.1620121204  
- **Tags:** vorticity, finite-element, navier-stokes  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Shallow water equations for equatorial tsunami waves

- **Key:** `83SXQR9F`  
- **Cite:** [22]  
- **URL/DOI:** DOI: 10.1098/rsta.2017.0100  
- **Tags:** tsunami, shallow-water, turbulence  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### NUMERICAL METHODS FOR SHALLOW-WATER FLOW

- **Key:** `8UH9AZC2`  
- **Cite:** [23]  
- **Tags:** shallow-water  
- **Access status:** unknown  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### A numerical study of the MRT-LBM for the shallow water equation in high Reynolds number flows: An application to real-world tsunami simulation

- **Key:** `C4HF4T4R`  
- **Cite:** [24]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S0029549323000080  
- **Tags:** tsunami, shallow-water, lbm  
- **Access status:** ScienceDirect indicates open access under Creative Commons with PDF view available.  

**Summary:** Studies a multiple-relaxation-time (MRT) lattice Boltzmann method (LBM) formulation for nonlinear shallow-water equations, targeting stability at high Reynolds numbers and real-world tsunami simulation (including the 2011 Great East Japan Earthquake). Highlights include demonstrating stability in high-Re flow, comparing results to a finite-difference method, and validating on benchmark problems including grid-size sensitivity.

**Equations / models to extract:** Equations not extracted from the landing page; obtain PDF and extract governing/discretized equations directly.

**Computational process to extract:** Extracted from accessible landing-page abstract/highlights; full computational details require PDF text parsing.

**Figures to capture (Codex instructions):** Capture: highlights/benchmark plots; grid-resolution comparison; tsunami run-up / inundation maps for 2011 event; any schematic of MRT vs BGK operator.

---

### Numerical techniques for the shallow water equations

- **Key:** `CEM7Z75L`  
- **Cite:** [25]  
- **URL/DOI:** https://www.reading.ac.uk/maths-and-stats/-/media/project/uor-main/schools-departments/maths/documents/0299pdf.pdf?la=en\&hash=10B5729D689DDBF51BFDF0F9C6AA3C82  
- **Tags:** shallow-water  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### The shallow water wave equation and tsunami propagation

- **Key:** `DJKB9NDL`  
- **Cite:** [26]  
- **URL/DOI:** https://terrytao.wordpress.com/2011/03/13/the-shallow-water-wave-equation-and-tsunami-propagation/  
- **Tags:** tsunami, shallow-water  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Numerical study on the hydrodynamic characteristics of submarine pipelines under the impact of real-world tsunami-like waves

- **Key:** `J7NR9DLP`  
- **Cite:** [27]  
- **URL/DOI:** DOI: 10.3390/w11020221  
- **Tags:** tsunami  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### a-new-method-for-the-numerical-solution-of-vorticity-streamfuncti

- **Key:** `LNK021`  
- **Cite:** [28]  
- **URL/DOI:** https://researchonline.gcu.ac.uk/en/publications/a-new-method-for-the-numerical-solution-of-vorticity-streamfuncti/  
- **Tags:** vorticity  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Vorticity-dynamics-and-sound-generation-in-two

- **Key:** `LNK036`  
- **Cite:** [29]  
- **URL/DOI:** https://pubs.aip.org/asa/jasa/article/122/1/128/812483/Vorticity-dynamics-and-sound-generation-in-two  
- **Tags:** vorticity  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### \textbackslash{

- **Key:** `LNK038`  
- **Cite:** [30]  
- **URL/DOI:** https://pubmed.ncbi.nlm.nih.gov/17614472/\#:\textasciitilde{:text=Abstract,a\%20general\%20distributed\%20vorticity\%20field.  
- **Tags:** vorticity  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 128\textbackslash{

- **Key:** `LNK039`  
- **Cite:** [31]  
- **URL/DOI:** https://watermark02.silverchair.com/128\_1\_online.pdf?token=AQECAHi208BE49Ooan9kkhW\_Ercy7Dm3ZL\_9Cf3qfKAc485ysgAABY0wggWJBgkqhkiG9w0BBwagggV6MIIFdgIBADCCBW8GCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQM9g\_qQQG4XgirHJ7TAgEQgIIFQHjWldyijCRli4eaC9mzYFqATsE6Oq-gW079wucNTBe4g1Ie8CLmWIX7AtT1hsJkiaUfsQJybGmAX4uVGLoYsDfZYgdNNDiVRrIcRT\_DL05LlL6PmeeRrrWiW2oVY9yJeHiEXbmPe41M7snfGXBVkLPueIMLDx9uQxaeqYAMkB0h4\_Itb1KqWKo\_yek5\_awwGr6FfBj0sWn0oVOEH507ex03aPSM-KP9feUbsBcTq1GdiEbOar4UcqVutXnC3eCV0BIrkN\_CJYDicmJnWnyZ3aznjrFfFsMy5JGffBnaaesiGdobz9rb-Vjhzf8PPfsd1IIsknu4REB3MASCTpoeSAPgoH7CAUd7QWut1-uoSeJ33vDJ3moLQqlPS\_uYpUYfF2MXePHnrBGjKfkVcjO6zFoYZLZbhpO\_Wvh7hSRrU\_VIl6MoOtewp7yTkGNiXuzaNxuFMaCsmAsFSXuD9jttPkzZsSTkTGdHCn-MSVHb6ydyy4tyQ2Yw-\_kkuTHQszlIqc7fGpaS9Ctw0Upfclk42Hmespgp4AJYixnt0tLDkSejzX346qYd0n-pswtddtugb1cL8Baxeww9FZBsmUePXV24RTh6x6ulYeiWDsNizA3HAdIrZ3I3cEXWK0J6n35\_CYIkDpOEPef2EbZZd6XI7rfuYttXVYEgp2Vjt0-oYXOK7tKi337F0O6WQnLvQ\_T7yEqnVwW3SbTFIzF79Eib8mYPlY3aa-ZfYyHIDPQAS9NVwmjvprEeBlYEmgj3K4U\_i\_zE8TKa3efQK7b-KeQEuuKyOoVqNd1uV-FJO-k-e0Cl\_IXnb7PW1f2erF9yvpbXhKBFXphhVrKIXrgmmzy2NzGtrZX8JKx3CGRRxVxJ33jzAWgAxZ0v7rtAK0Hr97D74IMq3WWDqL8-wRGef0-hrPcbo-sron81qer5iaaPIdv0pM\_cAWntYM77q3s4WXrPeuOZ1dB3aZEM7vBYioYeyPYVe1mNs5EuvpAlHyU\_25unmgM8eigchRyFGGA4rqnNSX8WSj1IkTZoIoANZs8RX29kcwymCsb4uVHGwW5aluCzeFJ24ke-vx6Zb2uKltP87NRjZpObWZ5CVCrV5xcpv6uXQXMvcnKt5aAelDPdUFeKLiVBpjLj-M4K\_qjnJM9xs07ESa0HXF4GhSBvtub0RLlP-8bAzC781f2\_Es\_qu4XWxlSO6xpLuxgYHKrFvwwVaS0HWbPZFSW5ppYMietNGPcCLF\_HHn7I9vVC0qvSQy-7RMsDUJzbHbkdqdwJmOeo7SEauJzxkPc1LSfuAW9nxWhP3fTKI6l9RC1ORDVrB83BVTY23hF80ni13svh3K1xnnK\_caaCKwZhnsNyZlIUZIBMTAbUHjd0szuwsTOOZe0Ddpy4yp4F5myKJMsWoTF-WN8obPkz1hsd-zyxdr7czIZ7aU16W0ouDml5vMGoQKcA9qMFpsUQCxiGGm-AuDaE1BPi\_BjoIuojKWjzh3i8iOo8N3oSZi5sGmu-KErylpldWpcDun0J6wSjUanjnsN4ruZU7cjYEWld3FfzlcoCID0cqSRxHvnLiaercHDIhos1DRcCH0y08CCei41hwYydN9uFmDHDTDNG9YnbNTUV1XGd6GdT1abSi77zH41NwxxqkXDi8T3xS6A0d5tU9VxaV8OgwK9Sc4wjalZ4yD4pD7gBgEnHhlIZEmHjYpVFulUKUUY\_rikBHXSNMxPw\_3vgLheKYJvl5vnV-Z2n3PPCBBcdBZ\_BTwwA2omBe9hWMPnvCRpM3ClYxBhhprFWsLWMjw  
- **Tags:** vorticity, lbm  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 271519995\textbackslash{

- **Key:** `LNK040`  
- **Cite:** [32]  
- **URL/DOI:** https://www.researchgate.net/publication/271519995\_RBF-Vortex\_Methods\_for\_the\_Barotropic\_Vorticity\_Equation\_on\_a\_Sphere  
- **Tags:** vorticity, sph  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### vortices-over-bathymetry

- **Key:** `LNK045`  
- **Cite:** [33]  
- **URL/DOI:** file:///C:/Users/Apoll/OneDrive\%20-\%20University\%20College\%20London/\%23University/Mechanical\%20Engineering/Year\%203/Term\%201/MECH0020\%20-\%20Numerical\%20Analysis\%20of\%20Tsunami\%20Vortices\%20in\%20Ocean\%20Surfaces/Research\%20Papers/vortices-over-bathymetry.pdf  
- **Tags:** tsunami, bathymetry  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 1-s2.0-S2590037423000663-main

- **Key:** `LNK048`  
- **Cite:** [34]  
- **URL/DOI:** file:///C:/Users/Apoll/OneDrive\%20-\%20University\%20College\%20London/\%23University/Mechanical\%20Engineering/Year\%203/Term\%201/MECH0020\%20-\%20Numerical\%20Analysis\%20of\%20Tsunami\%20Vortices\%20in\%20Ocean\%20Surfaces/Research\%20Papers/1-s2.0-S2590037423000663-main.pdf  
- **Tags:** tsunami  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### scholar\textbackslash{

- **Key:** `LNK055`  
- **Cite:** [35]  
- **URL/DOI:** https://scholar.google.com/scholar\_lookup?title=Review\%20of\%20tsunami\%20simulation\%20with\%20a\%20finite\%20difference\%20method\&publication\_year=1996\&author=F.\%20Imamura  
- **Tags:** tsunami  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Numerical study on the turbulent structure of tsunami bottom boundary layer using the 2011 tohoku tsunami waveform

- **Key:** `M5PIAXWZ`  
- **Cite:** [36]  
- **URL/DOI:** DOI: 10.3390/jmse10020173  
- **Tags:** tsunami, bathymetry  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Advanced numerical modelling of tsunami wave propagation, transformation and run-up

- **Key:** `QNI2R5I3`  
- **Cite:** [37]  
- **URL/DOI:** DOI: 10.1680/eacm.13.00029  
- **Tags:** tsunami, turbulence, runup  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Numerical methods for the nonlinear shallow water equations

- **Key:** `QQ2E4TQN`  
- **Cite:** [38]  
- **URL/DOI:** DOI: 10.1016/bs.hna.2016.09.003  
- **Tags:** shallow-water  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Numerical investigation of tsunami wave impacts on different coastal bridge decks using immersed boundary method

- **Key:** `RVKLA57C`  
- **Cite:** [39]  
- **URL/DOI:** DOI: 10.1016/j.oceaneng.2020.107132  
- **Tags:** tsunami  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Vorticity dynamics

- **Key:** `UA3DUAEL`  
- **Cite:** [40]  
- **URL/DOI:** https://linkinghub.elsevier.com/retrieve/pii/B9780128154892000071  
- **Tags:** vorticity  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Large eddy simulation modeling of tsunami-like solitary wave processes over fringing reefs

- **Key:** `UC6L8ZHR`  
- **Cite:** [41]  
- **URL/DOI:** DOI: 10.5194/nhess-19-1281-2019  
- **Tags:** tsunami  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Numerical investigation of tsunami-like wave hydrodynamic characteristics and its comparison with solitary wave

- **Key:** `V62NTNUQ`  
- **Cite:** [42]  
- **URL/DOI:** DOI: 10.1016/j.apor.2017.01.003  
- **Tags:** tsunami  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Shallow-water approximation

- **Key:** `YDE8HA5L`  
- **Cite:** [43]  
- **URL/DOI:** https://linkinghub.elsevier.com/retrieve/pii/B9780128154878000044  
- **Tags:** shallow-water  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Numerical simulation of tsunami-scale wave boundary layers

- **Key:** `ZSHYNA2A`  
- **Cite:** [44]  
- **URL/DOI:** DOI: 10.1016/j.coastaleng.2015.12.002  
- **Tags:** tsunami  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Long-wave Runup Models

- **Key:** `EWEW2MVE`  
- **Cite:** [45]  
- **URL/DOI:** https://books.google.co.uk/books?id=kUEoDwAAQBAJ\&lpg=PA25\&ots=804l4jr4Gt\&lr\&pg=PP1\#v=onepage\&q\&f=false  
- **Tags:** runup  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Modeling Spatio‐Temporal Transport: From Rigid Advection to Realistic Dynamics

- **Key:** `SLJX7XUP`  
- **Cite:** [46]  
- **URL/DOI:** DOI: 10.1002/env.70079  
- **Tags:** turbulence  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Unsteady aerodynamic loads on pitching aerofoils represented by Gaussian body force distributions

- **Key:** `3CHK5UFJ`  
- **Cite:** [47]  
- **URL/DOI:** https://www.cambridge.org/core/product/identifier/S0022112025108707/type/journal\_article  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Metrics and evaluations for computational and sustainable AI efficiency

- **Key:** `LVCKSYWR`  
- **Cite:** [48]  
- **Tags:** unclassified  
- **Access status:** unknown  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Metrics for Computational and Sustainable AI Efficiency

- **Key:** `RZB96MSQ`  
- **Cite:** [49]  
- **Tags:** unclassified  
- **Access status:** unknown  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Measuring Software Energy for a Sustainable Future: A Practical Guide

- **Key:** `VH4XV5BU`  
- **Cite:** [50]  
- **URL/DOI:** https://medium.com/@snehalbhatia8/measuring-software-energy-for-a-sustainable-future-a-practical-guide-2385359aef7b  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Analysis of wind turbine wake dynamics by a gaussian-core vortex lattice technique

- **Key:** `3K5JVPCF`  
- **Cite:** [51]  
- **URL/DOI:** https://www.mdpi.com/2673-8716/4/1/6  
- **Tags:** unclassified  
- **Access status:** likely open access (mdpi)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Numerical modelling of advection diffusion equation using Chebyshev spectral collocation method and Laplace transform

- **Key:** `6RYI78TN`  
- **Cite:** [52]  
- **URL/DOI:** DOI: 10.1016/j.rinam.2023.100420  
- **Tags:** spectral, advection-diffusion, turbulence  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Vortices over bathymetry

- **Key:** `F9FMHPDS`  
- **Cite:** [53]  
- **URL/DOI:** DOI: 10.1017/jfm.2023.1084  
- **Tags:** bathymetry  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Effect of the kinematic viscosity on liquid flow hydrodynamics in vortex mixers

- **Key:** `IACZM64D`  
- **Cite:** [54]  
- **URL/DOI:** DOI: 10.1016/j.cherd.2024.04.034  
- **Tags:** unclassified  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### A spatial local method for solving 2D and 3D advection-diffusion equations

- **Key:** `523LRD46`  
- **Cite:** [55]  
- **URL/DOI:** DOI: 10.1108/ec-06-2022-0434  
- **Tags:** advection-diffusion  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Viscous merging of three vortices

- **Key:** `5A3F6Y87`  
- **Cite:** [56]  
- **URL/DOI:** DOI: 10.1016/j.euromechflu.2022.12.014  
- **Tags:** unclassified  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### GREENER principles for environmentally sustainable computational science

- **Key:** `H4QX69B3`  
- **Cite:** [57]  
- **URL/DOI:** DOI: 10.1038/s43588-023-00461-y  
- **Tags:** turbulence  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### A maximum principle of the Fourier spectral method for diffusion equations

- **Key:** `WACZVN59`  
- **Cite:** [58]  
- **URL/DOI:** DOI: 10.3934/era.2023273  
- **Tags:** spectral  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Spectral3

- **Key:** `3QYM282P`  
- **Cite:** [59]  
- **URL/DOI:** https://www.youtube.com/watch?v=8lGLdnUYkj4  
- **Tags:** spectral  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### FD 1

- **Key:** `666FZA93`  
- **Cite:** [60]  
- **URL/DOI:** https://www.youtube.com/watch?v=g9xzv7Xe3w4  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### overcoming

- **Key:** `76VUM9IN`  
- **Cite:** [61]  
- **URL/DOI:** https://www.youtube.com/watch?v=umcxmDX2iVY  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Spectral1

- **Key:** `N2UTNRTT`  
- **Cite:** [62]  
- **URL/DOI:** https://www.youtube.com/watch?v=YKDptSCuQGY  
- **Tags:** spectral  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Spectral analysis and computation of effective diffusivities in space-time periodic incompressible flows

- **Key:** `DWRAZZH6`  
- **Cite:** [63]  
- **URL/DOI:** DOI: 10.4310/amsa.2017.v2.n1.a1  
- **Tags:** spectral, navier-stokes  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Interaction of multiple vortices over a double delta wing

- **Key:** `8A4U9P4H`  
- **Cite:** [64]  
- **URL/DOI:** DOI: 10.1016/j.ast.2015.11.020  
- **Tags:** unclassified  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Post-print archive

- **Key:** `5WBTXBH4`  
- **Cite:** [65]  
- **Tags:** unclassified  
- **Access status:** unknown  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### A coupled lattice Boltzmann and finite volume method for natural convection simulation

- **Key:** `VBW4M665`  
- **Cite:** [66]  
- **URL/DOI:** DOI: 10.1016/j.ijheatmasstransfer.2013.11.077  
- **Tags:** finite-volume, lbm, turbulence  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### A Lattice-Boltzmann solver for 3D fluid simulation on GPU

- **Key:** `TRSV998T`  
- **Cite:** [67]  
- **URL/DOI:** DOI: 10.1016/j.simpat.2012.03.004  
- **Tags:** unclassified  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Modelling vortex-vortex and vortex-boundary interaction

- **Key:** `S5PU436G`  
- **Cite:** [68]  
- **Tags:** unclassified  
- **Access status:** unknown  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### LATTICE BOLTZMANN METHOD FOR FLUID FLOWS

- **Key:** `CHKSLDH3`  
- **Cite:** [69]  
- **Tags:** lbm  
- **Access status:** unknown  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Quantitative experimental and numerical investigation of a vortex ring impinging on a wall

- **Key:** `3WG8ASE2`  
- **Cite:** [70]  
- **URL/DOI:** https://pubs.aip.org/pof/article/8/10/2640/259211/Quantitative-experimental-and-numerical  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### EQUATIONS OF FLUID MECHANICS

- **Key:** `2UXAPQTH`  
- **Cite:** [71]  
- **URL/DOI:** https://linkinghub.elsevier.com/retrieve/pii/B9780121678807500150  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Numerical Solution of the Advection-Diffusion Equation using the Discontinuous Enrichment Method (DEM)

- **Key:** `48U93KZ8`  
- **Cite:** [72]  
- **Tags:** sph, advection-diffusion  
- **Access status:** unknown  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Chapter 3

- **Key:** `FTVDGCVQ`  
- **Cite:** [73]  
- **Tags:** unclassified  
- **Access status:** unknown  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Numerical Solution of Advection-Diffusion-Reaction Equations

- **Key:** `FWNDDZNQ`  
- **Cite:** [74]  
- **Tags:** advection-diffusion  
- **Access status:** unknown  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Reviewer

- **Key:** `GXH7LEHG`  
- **Cite:** [75]  
- **URL/DOI:** DOI: 10.18637/jss.v067.b01  
- **Tags:** unclassified  
- **Access status:** doi landing page required  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### overcoming

- **Key:** `L255D6QK`  
- **Cite:** [76]  
- **URL/DOI:** https://www.youtube.com/watch?v=umcxmDX2iVY  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 1161283

- **Key:** `LNK001`  
- **Cite:** [77]  
- **URL/DOI:** https://agu.confex.com/agu/fm22/meetingapp.cgi/Paper/1161283  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S2590037423000663

- **Key:** `LNK002`  
- **Cite:** [78]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S2590037423000663  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### ssostart

- **Key:** `LNK003`  
- **Cite:** [79]  
- **URL/DOI:** https://onlinelibrary.wiley.com/action/ssostart?redirectUri=\%2Fdoi\%2Ffull\%2F10.1002\%2Fenv.70079\%3Fsaml\_referrer  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S2590037423000663

- **Key:** `LNK004`  
- **Cite:** [80]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S2590037423000663?ref=pdf\_download\&fr=RR-2\&rr=9cc649013a5a48b8  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 350875965\textbackslash{

- **Key:** `LNK005`  
- **Cite:** [81]  
- **URL/DOI:** https://www.researchgate.net/publication/350875965\_A\_spatial\_local\_method\_for\_solving\_2D\_and\_3D\_advection-diffusion\_equations  
- **Tags:** advection-diffusion  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 66bdd115ac105ea17af303e73d4fec449754-v448bk

- **Key:** `LNK006`  
- **Cite:** [82]  
- **URL/DOI:** https://bpb-us-e1.wpmucdn.com/blogs.gwu.edu/dist/9/297/files/2018/01/66bdd115ac105ea17af303e73d4fec449754-v448bk.pdf  
- **Tags:** turbulence  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 2404.18754

- **Key:** `LNK007`  
- **Cite:** [83]  
- **URL/DOI:** https://arxiv.org/pdf/2404.18754  
- **Tags:** unclassified  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### melosh08\textbackslash{

- **Key:** `LNK008`  
- **Cite:** [84]  
- **URL/DOI:** https://www.sandia.gov/app/uploads/sites/127/2021/11/melosh08\_kalashnikova.pdf  
- **Tags:** unclassified  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### order

- **Key:** `LNK009`  
- **Cite:** [85]  
- **URL/DOI:** https://global-sci.com/csiam-am/order  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 144012989

- **Key:** `LNK010`  
- **Cite:** [86]  
- **URL/DOI:** https://files01.core.ac.uk/download/pdf/144012989.pdf?\_\_cf\_chl\_tk=IPACHLogny8G0TTNbnTMucMyFenXwYhN.jsJk8BUWFk-1770590769-1.0.1.1-NNdbqwsScPW74mnTDvO29rnBtUDBl\_ZUvVAKggSihR4  
- **Tags:** turbulence  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 7801

- **Key:** `LNK011`  
- **Cite:** [87]  
- **URL/DOI:** https://global-sci.com/index.php/csiam-am/article/view/7801  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 1

- **Key:** `LNK012`  
- **Cite:** [88]  
- **URL/DOI:** https://pubs.aip.org/aip/acp/issue/1148/1  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 144012989

- **Key:** `LNK013`  
- **Cite:** [89]  
- **URL/DOI:** https://files01.core.ac.uk/download/pdf/144012989.pdf?\_\_cf\_chl\_tk=trsdNgCnVuUXrOYh1wa\_8Flcd.ug8xkkKem4NsHDDgw-1770679354-1.0.1.1-yLmVpJfRLntuNHaws8.qxCmM2CPqRIYXSNP3A82ukFM  
- **Tags:** turbulence  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 080704\textbackslash{

- **Key:** `LNK014`  
- **Cite:** [90]  
- **URL/DOI:** https://www.meteo.physik.uni-muenchen.de/\textasciitilde{roger/Lectures/Tropical\_Cyclones/080704\_TCs\_Part\_II\_Chapter01.pdf  
- **Tags:** unclassified  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 1

- **Key:** `LNK015`  
- **Cite:** [91]  
- **URL/DOI:** https://pubs.aip.org/aip/acp/issue/1148/1?\_\_cf\_chl\_tk=l6I3CRcpd9p7KJSKswBRQ5SOcaR8WAlvNcelJsRewDE-1770679336-1.0.1.1-kE9gDf\_lBn1OvBhehxlPY2SEFL\_CdBfBrQUJznJ2ky0  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S0045782508002855

- **Key:** `LNK016`  
- **Cite:** [92]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S0045782508002855?ref=pdf\_download\&fr=RR-2\&rr=9cc649130ed448b8  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S0045782508002855

- **Key:** `LNK017`  
- **Cite:** [93]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S0045782508002855?via=ihub  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### authorization.oauth2

- **Key:** `LNK018`  
- **Cite:** [94]  
- **URL/DOI:** https://id.elsevier.com/as/authorization.oauth2?platSite=SD\%2Fscience\&additionalPlatSites=GH\%2Fgeneralhospital\%2CMDY\%2Fmendeley\%2CSC\%2Fscopus\%2CRX\%2Freaxys\&scope=openid\%20email\%20profile\%20els\_auth\_info\%20els\_idp\_info\%20els\_idp\_analytics\_attrs\%20els\_sa\_discover\%20urn\%3Acom\%3Aelsevier\%3Aidp\%3Apolicy\%3Aproduct\%3Ainst\_assoc\&response\_type=code\&redirect\_uri=https\%3A\%2F\%2Fwww.sciencedirect.com\%2Fuser\%2Fidentity\%2Flanding\&authType=SINGLE\_SIGN\_IN\&prompt=login\&client\_id=SDFE-v4\&state=retryCounter\%3D0\%26csrfToken\%3Dec5498f9-960d-4a28-8b37-c0ef94587b8d\%26idpPolicy\%3Durn\%253Acom\%253Aelsevier\%253Aidp\%253Apolicy\%253Aproduct\%253Ainst\_assoc\%26returnUrl\%3Dhttps\%253A\%252F\%252Fwww.sciencedirect.com\%252Fscience\%252Farticle\%252Fabs\%252Fpii\%252FS0045782508002855\%253Fvia\%253Dihub\%26prompt\%3Dlogin  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### deliverInstCredentials

- **Key:** `LNK019`  
- **Cite:** [95]  
- **URL/DOI:** https://auth.elsevier.com/ShibAuth/deliverInstCredentials  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S0263876224002363

- **Key:** `LNK020`  
- **Cite:** [96]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S0263876224002363  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Lecture05

- **Key:** `LNK022`  
- **Cite:** [97]  
- **URL/DOI:** https://sites.fem.unicamp.br/\textasciitilde{phoenics/SITE\_PHOENICS/Apostilas/CFD-1\_U\%20Michigan\_Hong/Lecture05.pdf  
- **Tags:** finite-element  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### premium-announcement

- **Key:** `LNK023`  
- **Cite:** [98]  
- **URL/DOI:** https://languagetool.org/webextension/premium-announcement?type=background\_tab\&utm\_campaign=addon2-trial-page  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 2506.05081

- **Key:** `LNK024`  
- **Cite:** [99]  
- **URL/DOI:** https://arxiv.org/pdf/2506.05081  
- **Tags:** unclassified  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### item

- **Key:** `LNK025`  
- **Cite:** [100]  
- **URL/DOI:** https://news.ycombinator.com/item?id=44838661  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### introduction-to-ansys-apdl-programming-easy-hand-on-bar-example-of-learning-apdl-8f584e1be5f7

- **Key:** `LNK026`  
- **Cite:** [101]  
- **URL/DOI:** https://a5833959.medium.com/introduction-to-ansys-apdl-programming-easy-hand-on-bar-example-of-learning-apdl-8f584e1be5f7  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### ansys-apdl-code-example

- **Key:** `LNK027`  
- **Cite:** [102]  
- **URL/DOI:** https://www.scribd.com/document/50005310/ansys-apdl-code-example  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S1569190X1200038X

- **Key:** `LNK028`  
- **Cite:** [103]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S1569190X1200038X?ref=pdf\_download\&fr=RR-2\&rr=9cc6493998aede7d  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S0017931013010417

- **Key:** `LNK029`  
- **Cite:** [104]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S0017931013010417?ref=pdf\_download\&fr=RR-2\&rr=9cc6493998b1de7d  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### books

- **Key:** `LNK030`  
- **Cite:** [105]  
- **URL/DOI:** https://books.google.co.uk/books?hl=en\&lr=\&id=kUEoDwAAQBAJ\&oi=fnd\&pg=PA25\&ots=804l4jr4Gt\&sig=Dz44Dj2KiC57KnlLxdKhMF4Krgs\&redir\_esc=y\#v=onepage\&q\&f=false  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### annurev.fluid.30.1.329

- **Key:** `LNK031`  
- **Cite:** [106]  
- **URL/DOI:** https://www.annualreviews.org/content/journals/10.1146/annurev.fluid.30.1.329  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S0029549323000080

- **Key:** `LNK032`  
- **Cite:** [107]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S0029549323000080?ref=pdf\_download\&fr=RR-2\&rr=9cc6493998adde7d  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### pdf

- **Key:** `LNK033`  
- **Cite:** [108]  
- **URL/DOI:** https://iopscience.iop.org/article/10.1088/1367-2630/ab1bb5/pdf  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S1270963815003648

- **Key:** `LNK034`  
- **Cite:** [109]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S1270963815003648?ref=pdf\_download\&fr=RR-2\&rr=9cc6493b3cb9de7d  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S1270963815003648

- **Key:** `LNK035`  
- **Cite:** [110]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S1270963815003648  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 19222

- **Key:** `LNK037`  
- **Cite:** [111]  
- **URL/DOI:** https://discovery.ucl.ac.uk/id/eprint/19222/1/19222.pdf  
- **Tags:** unclassified  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### chapter3

- **Key:** `LNK041`  
- **Cite:** [112]  
- **URL/DOI:** https://people.bath.ac.uk/jhpd20/teaching/fluids/chapter3.pdf  
- **Tags:** unclassified  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 1328flan

- **Key:** `LNK042`  
- **Cite:** [113]  
- **URL/DOI:** https://www.maths.dur.ac.uk/lms/106/talks/1328flan.pdf  
- **Tags:** unclassified  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Dam2023\textbackslash{

- **Key:** `LNK043`  
- **Cite:** [114]  
- **URL/DOI:** https://rucforsk.ruc.dk/ws/portalfiles/portal/87924215/Dam2023\_Viscous\_merging\_3\_vort.pdf  
- **Tags:** turbulence  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### chpthree.PDF

- **Key:** `LNK044`  
- **Cite:** [115]  
- **URL/DOI:** https://math.nyu.edu/\textasciitilde{childres/chpthree.PDF  
- **Tags:** unclassified  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### E2BD59CDE6BA9052BED8FF9B20A71025

- **Key:** `LNK046`  
- **Cite:** [116]  
- **URL/DOI:** https://www.cambridge.org/core/journals/journal-of-fluid-mechanics/article/vortices-over-bathymetry/E2BD59CDE6BA9052BED8FF9B20A71025  
- **Tags:** bathymetry  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### A-spatial-local-method-for-solving-2D-and-3D-advection-diffusion-equations

- **Key:** `LNK047`  
- **Cite:** [117]  
- **URL/DOI:** https://www.researchgate.net/publication/350875965\_A\_spatial\_local\_method\_for\_solving\_2D\_and\_3D\_advection-diffusion\_equations/fulltext/6077af3f907dcf667b9d39bb/A-spatial-local-method-for-solving-2D-and-3D-advection-diffusion-equations.pdf?origin=publication\_detail\&\_tp=eyJjb250ZXh0Ijp7ImZpcnN0UGFnZSI6InB1YmxpY2F0aW9uIiwicGFnZSI6InB1YmxpY2F0aW9uRG93bmxvYWQiLCJwcmV2aW91c1BhZ2UiOiJwdWJsaWNhdGlvbiJ9fQ\&\_\_cf\_chl\_tk=PhzEL1zL\_6YajW\_UzCWqJVM9Z9W1ptxu6xYZL4eMxcU-1770656816-1.0.1.1-1O3EJU2d14T7EoixlF0jAGGvW5ZRfzDSG2mQ4hQrLjw  
- **Tags:** advection-diffusion  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S2590037423000663

- **Key:** `LNK049`  
- **Cite:** [118]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S2590037423000663?ref=pdf\_download\&fr=RR-2\&rr=9cc6495b38d4d56f  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### era-31-09-273

- **Key:** `LNK050`  
- **Cite:** [119]  
- **URL/DOI:** https://www.aimspress.com/aimspress-data/era/2023/9/PDF/era-31-09-273.pdf  
- **Tags:** unclassified  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S0263876224002363

- **Key:** `LNK051`  
- **Cite:** [120]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S0263876224002363?ref=pdf\_download\&fr=RR-2\&rr=9cc649617a96d56f  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S2590037423000663

- **Key:** `LNK052`  
- **Cite:** [121]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S2590037423000663?\_\_cf\_chl\_rt\_tk=3vmcD61f6wLCJ2vgFtS.R2hTyTtMeIY0YvZP8VovTFw-1770655790-1.0.1.1-801bEQoKN.fjyDj6a9IsG5JjErQYw5EwQTMfvMZxuEc  
- **Tags:** finite-volume  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S1569190X1200038X

- **Key:** `LNK053`  
- **Cite:** [122]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S1569190X1200038X?via\%3Dihub  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S0017931013010417

- **Key:** `LNK054`  
- **Cite:** [123]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S0017931013010417?via\%3Dihub  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### S0029549323000080\textbackslash{

- **Key:** `LNK056`  
- **Cite:** [124]  
- **URL/DOI:** https://www.sciencedirect.com/science/article/pii/S0029549323000080\#sec2  
- **Tags:** unclassified  
- **Access status:** publisher page (may be OA or paywalled)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### endnote.com

- **Key:** `LNK057`  
- **Cite:** [125]  
- **URL/DOI:** https://endnote.com/?srsltid=AfmBOor0KxRx\_JWS2UWsDdAVm6O8AOA82ednmeVG-fiKntitpSAu5MQ2  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### free-trial

- **Key:** `LNK058`  
- **Cite:** [126]  
- **URL/DOI:** https://endnote.com/free-trial/  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### s43588-023-00461-y

- **Key:** `LNK059`  
- **Cite:** [127]  
- **URL/DOI:** https://www.nature.com/articles/s43588-023-00461-y  
- **Tags:** turbulence  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### 2510.17885

- **Key:** `LNK060`  
- **Cite:** [128]  
- **URL/DOI:** https://www.arxiv.org/pdf/2510.17885  
- **Tags:** unclassified  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### cfd5

- **Key:** `LNK061`  
- **Cite:** [129]  
- **URL/DOI:** https://web.math.princeton.edu/\textasciitilde{weinan/papers/cfd5.pdf  
- **Tags:** unclassified  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### Data-Driven Modeling \textbackslash{

- **Key:** `LPK7KYNX`  
- **Cite:** [130]  
- **URL/DOI:** https://faculty.washington.edu/kutz/kutz\_book\_v2.pdf  
- **Tags:** unclassified  
- **Access status:** direct pdf link (attempt download)  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---

### https://www.researchgate.net/publication/352160233\textbackslash{

- **Key:** `SG9B7EWZ`  
- **Cite:** [131]  
- **URL/DOI:** https://www.researchgate.net/publication/352160233\_Analytical\_Effects\_of\_Torsion\_on\_Timber\_Beams  
- **Tags:** unclassified  
- **Access status:** web resource  

**Summary:** Full-text summary not extracted from the provided metadata alone. For a complete summary: open the DOI/URL, copy the abstract, then extract the method section (governing equations, discretization, stability/CFL, boundary conditions), and the results section (validation, benchmarks, error metrics, convergence, runtime).

**Equations / models to extract:** If the source uses vorticity--streamfunction or SWE, map its notation onto Eqs.\textasciitilde{}\eqref\{eq:swe\_mass\}--\eqref\{eq:advdiff\} and record any modifications (dispersion, friction, turbulence closure).

**Computational process to extract:** Record: grid/particle resolution, timestep rule, solver (explicit RK, implicit, multigrid), boundary/wet--dry handling, and validation cases.

**Figures to capture (Codex instructions):** Capture: (i) domain/grid schematic; (ii) validation vs experiment/analytic; (iii) error vs resolution; (iv) vortex/velocity snapshots; (v) run-up/inundation maps if present.

---


## Bibliography (Vancouver, numeric)

1. Computational Fluid Dynamics: Shallow water modeling [Internet]. 2024. [cited 2026 Feb 11]. Available from: https://www.mighte.org/computational-fluid-dynamics-shallow-water-modeling.html.
2. Dai Z, Li X, Lan B. Three-Dimensional Modeling of Tsunami Waves Triggered by Submarine Landslides Based on the Smoothed Particle Hydrodynamics Method. Journal of Marine Science and Engineering. 2023;11.0(10):2015-2015. doi:10.3390/jmse11102015.
3. Sahoo B, Singh CR, Sahu D, Sahoo R, Alam Je. Impact of vorticity and viscosity on the hydrodynamic evolution of hot QCD medium. The European Physical Journal C. 2023;83.0(9). doi:10.1140/epjc/s10052-023-12027-3.
4. Tinh NX, Tanaka H, Yu X, Liu G. Numerical Study on the Turbulent Structure of Tsunami Bottom Boundary Layer Using the 2011 Tohoku Tsunami Waveform. Journal of Marine Science and Engineering. 2022;10.0(2):173. doi:10.3390/jmse10020173.
5. Bandyopadhyay A, Manna S, Maji D. Hydrodynamic aspects of tsunami wave motion: a review [Internet]. 2021. [cited 2026 Feb 11]. Available from: https://www.researchgate.net/publication/350821621\_Hydrodynamic\_aspects\_of\_tsunami\_wave\_motion\_a\_review.
6. Forstner S, Sachkou Y, Woolley M, Harris GI, He X, Bowen WP, Baker CG. Modelling of vorticity, sound and their interaction in two-dimensional superfluids. New Journal of Physics. 2019;21.0(5):053029. doi:10.1088/1367-2630/ab1bb5.
7. Boshenyatov B, Zhiltsov K. Vortex suppression of tsunami-like waves by underwater barriers. Ocean Engineering. 2019;183.0:398-408. doi:10.1016/j.oceaneng.2019.05.011.
8. Zhao E, Tang Y, Shao J, Mu L. Numerical Analysis of Hydrodynamics Around Submarine Pipeline End Manifold (PLEM) Under Tsunami-Like Wave. IEEE Access. 2019;7.0:178903-178917. doi:10.1109/access.2019.2957395.
9. Flandoli F. Weak vorticity formulation of 2D Euler equations with white noise initial condition. Communications in Partial Differential Equations. 2018;43.0(7):1102-1149. doi:10.1080/03605302.2018.1467448.
10. Chen J, Jiang C, Yang W, Xiao G. Laboratory study on protection of tsunamiinduced scour by offshore breakwaters. Natural Hazards. 2016;81.0. doi:10.1007/s110690152131x.
11. Salih A. Streamfunction-Vorticity Formulation. 2013. Available from: https://old.iist.ac.in/sites/default/files/people/psi-omega.pdf.
12. Namdar A, Nusrath A. Tsunami numerical modeling and mitigation. Frattura ed Integrità Strutturale. 2010;4.0(12):57-62. doi:10.3221/igf-esis.12.06.
13. Yamamoto H, Segur H. Lecture 8: The Shallow-Water Equations. 2009. Available from: https://gfd.whoi.edu/wp-content/uploads/sites/18/2018/03/lecture8-harvey\_136564.pdf.
14. Nagem R, Sandri G, Uminsky D. Vorticity dynamics and sound generation in two-dimensional fluid flow Articles You May Be Interested In Validation of a hybrid method of aeroacoustic noise computation applied to internal flows Vorticity dynamics and sound generation in two-dimensional fluid flow. J. Acoust. Soc. Am. 2007;122.0:128-134.
15. Dubois F, Salaün M, Salmon S. First vorticity–velocity–pressure numerical scheme for the Stokes problem. Computer Methods in Applied Mechanics and Engineering. 2003;192.0(44):4877-4907. doi:10.1016/S0045-7825(03)00377-3.
16. E W, Liu JG. Vorticity Boundary Condition and Related Issues for Finite Difference Schemes. Journal of Computational Physics. 1996;124.0(2):368-382. doi:10.1006/jcph.1996.0066.
17. 16: Stream function, vorticity equations [Internet]. [cited 2026 Feb 11]. Available from: https://math.libretexts.org/Bookshelves/Scientific\_Computing\_Simulations\_and\_Modeling/Scientific\_Computing\_(Chasnov)/III\%3A\_Computational\_Fluid\_Dynamics/16\%3A\_Stream\_Function\_Vorticity\_Equations.
18. Dias F, Dutykh D, O’Brien L, Renzi E, Stefanakis T. On the modelling of tsunami generation and tsunami inundation. Procedia IUTAM.10.0:338-355. doi:10.1016/j.piutam.2014.01.029.
19. +xgvrq X. Numerical Techniques for the Shallow Water Equations. Available from: https://www.reading.ac.uk/maths-and-stats/-/media/project/uor-main/schools-departments/maths/documents/0299pdf.pdf?la=en\&hash=10B5729D689DDBF51BFDF0F9C6AA3C82.
20. LIu JG, E W. SIMPLE FINITE ELEMENT METHOD IN VORTICITY FORMULATION FOR INCOMPRESSIBLE FLOWS. Available from: \url{https://web.math.princeton.edu/\textasciitilde{}weinan/papers/cfd9.pdf}.
21. Campion‐Renson A, Crochet MJ. On the stream function‐vorticity finite element solutions of Navier‐Stokes equations. International Journal for Numerical Methods in Engineering.12.0(12):1809-1818. doi:10.1002/nme.1620121204.
22. Geyer A, Quirchmayr R. Shallow water equations for equatorial tsunami waves. Philosophical Transactions of the Royal Society A Mathematical Physical and Engineering Sciences.376.0(2111):20170100-20170100. doi:10.1098/rsta.2017.0100.
23. . NUMERICAL METHODS FOR SHALLOW-WATER FLOW.
24. Sato K, Kawasaki K, Koshimura S. A numerical study of the MRT-LBM for the shallow water equation in high Reynolds number flows: An application to real-world tsunami simulation. Nuclear Engineering and Design.404.0:112159. doi:10.1016/j.nucengdes.2023.112159.
25. xgvrq X. Numerical techniques for the shallow water equations. Available from: https://www.reading.ac.uk/maths-and-stats/-/media/project/uor-main/schools-departments/maths/documents/0299pdf.pdf?la=en\&hash=10B5729D689DDBF51BFDF0F9C6AA3C82.
26. Tao T. The shallow water wave equation and tsunami propagation [Internet]. [cited 2026 Feb 11]. Available from: https://terrytao.wordpress.com/2011/03/13/the-shallow-water-wave-equation-and-tsunami-propagation/.
27. Zhao E, Qu K, Mu L, Kraatz S, Shi B. Numerical study on the hydrodynamic characteristics of submarine pipelines under the impact of real-world tsunami-like waves. Water.11.0(2):221-221. doi:10.3390/w11020221.
28. a-new-method-for-the-numerical-solution-of-vorticity-streamfuncti [Internet]. [cited 2026 Feb 11]. Available from: https://researchonline.gcu.ac.uk/en/publications/a-new-method-for-the-numerical-solution-of-vorticity-streamfuncti/.
29. Vorticity-dynamics-and-sound-generation-in-two [Internet]. [cited 2026 Feb 11]. Available from: https://pubs.aip.org/asa/jasa/article/122/1/128/812483/Vorticity-dynamics-and-sound-generation-in-two.
30. #:~:text=Abstract,a%20general%20distributed%20vorticity%20field. [Internet]. [cited 2026 Feb 11]. Available from: \url{https://pubmed.ncbi.nlm.nih.gov/17614472/\#:\textasciitilde{}:text=Abstract,a\%20general\%20distributed\%20vorticity\%20field.}.
31. 128_1_online [Internet]. [cited 2026 Feb 11]. Available from: https://watermark02.silverchair.com/128\_1\_online.pdf?token=AQECAHi208BE49Ooan9kkhW\_Ercy7Dm3ZL\_9Cf3qfKAc485ysgAABY0wggWJBgkqhkiG9w0BBwagggV6MIIFdgIBADCCBW8GCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQM9g\_qQQG4XgirHJ7TAgEQgIIFQHjWldyijCRli4eaC9mzYFqATsE6Oq-gW079wucNTBe4g1Ie8CLmWIX7AtT1hsJkiaUfsQJybGmAX4uVGLoYsDfZYgdNNDiVRrIcRT\_DL05LlL6PmeeRrrWiW2oVY9yJeHiEXbmPe41M7snfGXBVkLPueIMLDx9uQxaeqYAMkB0h4\_Itb1KqWKo\_yek5\_awwGr6FfBj0sWn0oVOEH507ex03aPSM-KP9feUbsBcTq1GdiEbOar4UcqVutXnC3eCV0BIrkN\_CJYDicmJnWnyZ3aznjrFfFsMy5JGffBnaaesiGdobz9rb-Vjhzf8PPfsd1IIsknu4REB3MASCTpoeSAPgoH7CAUd7QWut1-uoSeJ33vDJ3moLQqlPS\_uYpUYfF2MXePHnrBGjKfkVcjO6zFoYZLZbhpO\_Wvh7hSRrU\_VIl6MoOtewp7yTkGNiXuzaNxuFMaCsmAsFSXuD9jttPkzZsSTkTGdHCn-MSVHb6ydyy4tyQ2Yw-\_kkuTHQszlIqc7fGpaS9Ctw0Upfclk42Hmespgp4AJYixnt0tLDkSejzX346qYd0n-pswtddtugb1cL8Baxeww9FZBsmUePXV24RTh6x6ulYeiWDsNizA3HAdIrZ3I3cEXWK0J6n35\_CYIkDpOEPef2EbZZd6XI7rfuYttXVYEgp2Vjt0-oYXOK7tKi337F0O6WQnLvQ\_T7yEqnVwW3SbTFIzF79Eib8mYPlY3aa-ZfYyHIDPQAS9NVwmjvprEeBlYEmgj3K4U\_i\_zE8TKa3efQK7b-KeQEuuKyOoVqNd1uV-FJO-k-e0Cl\_IXnb7PW1f2erF9yvpbXhKBFXphhVrKIXrgmmzy2NzGtrZX8JKx3CGRRxVxJ33jzAWgAxZ0v7rtAK0Hr97D74IMq3WWDqL8-wRGef0-hrPcbo-sron81qer5iaaPIdv0pM\_cAWntYM77q3s4WXrPeuOZ1dB3aZEM7vBYioYeyPYVe1mNs5EuvpAlHyU\_25unmgM8eigchRyFGGA4rqnNSX8WSj1IkTZoIoANZs8RX29kcwymCsb4uVHGwW5aluCzeFJ24ke-vx6Zb2uKltP87NRjZpObWZ5CVCrV5xcpv6uXQXMvcnKt5aAelDPdUFeKLiVBpjLj-M4K\_qjnJM9xs07ESa0HXF4GhSBvtub0RLlP-8bAzC781f2\_Es\_qu4XWxlSO6xpLuxgYHKrFvwwVaS0HWbPZFSW5ppYMietNGPcCLF\_HHn7I9vVC0qvSQy-7RMsDUJzbHbkdqdwJmOeo7SEauJzxkPc1LSfuAW9nxWhP3fTKI6l9RC1ORDVrB83BVTY23hF80ni13svh3K1xnnK\_caaCKwZhnsNyZlIUZIBMTAbUHjd0szuwsTOOZe0Ddpy4yp4F5myKJMsWoTF-WN8obPkz1hsd-zyxdr7czIZ7aU16W0ouDml5vMGoQKcA9qMFpsUQCxiGGm-AuDaE1BPi\_BjoIuojKWjzh3i8iOo8N3oSZi5sGmu-KErylpldWpcDun0J6wSjUanjnsN4ruZU7cjYEWld3FfzlcoCID0cqSRxHvnLiaercHDIhos1DRcCH0y08CCei41hwYydN9uFmDHDTDNG9YnbNTUV1XGd6GdT1abSi77zH41NwxxqkXDi8T3xS6A0d5tU9VxaV8OgwK9Sc4wjalZ4yD4pD7gBgEnHhlIZEmHjYpVFulUKUUY\_rikBHXSNMxPw\_3vgLheKYJvl5vnV-Z2n3PPCBBcdBZ\_BTwwA2omBe9hWMPnvCRpM3ClYxBhhprFWsLWMjw.
32. 271519995_RBF-Vortex_Methods_for_the_Barotropic_Vorticity_Equation_on_a_Sphere [Internet]. [cited 2026 Feb 11]. Available from: https://www.researchgate.net/publication/271519995\_RBF-Vortex\_Methods\_for\_the\_Barotropic\_Vorticity\_Equation\_on\_a\_Sphere.
33. vortices-over-bathymetry [Internet]. [cited 2026 Feb 11]. Available from: file:///C:/Users/Apoll/OneDrive\%20-\%20University\%20College\%20London/\%23University/Mechanical\%20Engineering/Year\%203/Term\%201/MECH0020\%20-\%20Numerical\%20Analysis\%20of\%20Tsunami\%20Vortices\%20in\%20Ocean\%20Surfaces/Research\%20Papers/vortices-over-bathymetry.pdf.
34. 1-s2.0-S2590037423000663-main [Internet]. [cited 2026 Feb 11]. Available from: file:///C:/Users/Apoll/OneDrive\%20-\%20University\%20College\%20London/\%23University/Mechanical\%20Engineering/Year\%203/Term\%201/MECH0020\%20-\%20Numerical\%20Analysis\%20of\%20Tsunami\%20Vortices\%20in\%20Ocean\%20Surfaces/Research\%20Papers/1-s2.0-S2590037423000663-main.pdf.
35. scholar_lookup [Internet]. [cited 2026 Feb 11]. Available from: https://scholar.google.com/scholar\_lookup?title=Review\%20of\%20tsunami\%20simulation\%20with\%20a\%20finite\%20difference\%20method\&publication\_year=1996\&author=F.\%20Imamura.
36. Xuan TN, Tanaka H, Yu X, Liu G. Numerical study on the turbulent structure of tsunami bottom boundary layer using the 2011 tohoku tsunami waveform. Journal of Marine Science and Engineering.10.0(2):173. doi:10.3390/jmse10020173.
37. Dimakopoulos AS, Guercio A, Cuomo G. Advanced numerical modelling of tsunami wave propagation, transformation and run-up. Proceedings of the Institution of Civil Engineers - Engineering and Computational Mechanics.167.0(3):139-151. doi:10.1680/eacm.13.00029.
38. Xing Y. Numerical methods for the nonlinear shallow water equations. Handbook of numerical analysis. doi:10.1016/bs.hna.2016.09.003.
39. Zhao E, Sun J, Tang Y, Mu L, Jiang H. Numerical investigation of tsunami wave impacts on different coastal bridge decks using immersed boundary method. Ocean Engineering.201.0:107132. doi:10.1016/j.oceaneng.2020.107132.
40. Katopodes ND. Vorticity dynamics. Elsevier; Available from: https://linkinghub.elsevier.com/retrieve/pii/B9780128154892000071.
41. Yao Y, He T, Deng Z, Chen L, Guo H. Large eddy simulation modeling of tsunami-like solitary wave processes over fringing reefs. Natural hazards and earth system sciences.19.0(6):1281-1295. doi:10.5194/nhess-19-1281-2019.
42. Qu K, Ren XY, Kraatz S. Numerical investigation of tsunami-like wave hydrodynamic characteristics and its comparison with solitary wave. Applied Ocean Research.63.0:36-48. doi:10.1016/j.apor.2017.01.003.
43. Katopodes ND. Shallow-water approximation. Elsevier; Available from: https://linkinghub.elsevier.com/retrieve/pii/B9780128154878000044.
44. Williams IA, Fuhrman DR. Numerical simulation of tsunami-scale wave boundary layers. Coastal Engineering.110.0:17-31. doi:10.1016/j.coastaleng.2015.12.002.
45. Long-wave Runup Models [Internet]. 2026. [cited 2026 Feb 11]. Available from: https://books.google.co.uk/books?id=kUEoDwAAQBAJ\&lpg=PA25\&ots=804l4jr4Gt\&lr\&pg=PP1\#v=onepage\&q\&f=false.
46. Battagliola ML, Olhede SC. Modeling Spatio‐Temporal Transport: From Rigid Advection to Realistic Dynamics. Environmetrics. 2026;37.0(2). doi:10.1002/env.70079.
47. Taschner E, Deskos G, Kuhn MB, Wingerden V, Martínez-Tossas LA. Unsteady aerodynamic loads on pitching aerofoils represented by Gaussian body force distributions. Journal of Fluid Mechanics. 2025;1024.0:A15. doi:10.1017/jfm.2025.10870.
48. Liu H, Liu X, Hu G. Metrics and evaluations for computational and sustainable AI efficiency. 2025.
49. Liu H, Liu X, Hu G. Metrics for Computational and Sustainable AI Efficiency. 2025.
50. Bhatia S. Measuring Software Energy for a Sustainable Future: A Practical Guide [Internet]. 2025. [cited 2026 Feb 11]. Available from: https://medium.com/@snehalbhatia8/measuring-software-energy-for-a-sustainable-future-a-practical-guide-2385359aef7b.
51. Baruah A, Ponta F. Analysis of wind turbine wake dynamics by a gaussian-core vortex lattice technique. Dynamics. 2024;4.0(1):97-118. doi:10.3390/dynamics4010006.
52. Shah FA, Kamran, Shah K, Abdeljawad T. Numerical modelling of advection diffusion equation using Chebyshev spectral collocation method and Laplace transform. Results in Applied Mathematics. 2024;21.0:100420. doi:10.1016/j.rinam.2023.100420.
53. LaCasce JH, Palóczy A, Trodahl M. Vortices over bathymetry. Journal of Fluid Mechanics. 2024;979.0. doi:10.1017/jfm.2023.1084.
54. GECIM G, ERKOC E. Effect of the kinematic viscosity on liquid flow hydrodynamics in vortex mixers. Chemical Engineering Research and Design. 2024;206.0:54-61. doi:10.1016/j.cherd.2024.04.034.
55. Tunc H, Sari M. A spatial local method for solving 2D and 3D advection-diffusion equations. Engineering Computations. 2023;40.0(9/10):2068-2089. doi:10.1108/ec-06-2022-0434.
56. Dam MJB, Hansen JS, Andersen M. Viscous merging of three vortices. European Journal of Mechanics - B/Fluids. 2023;99.0:17-22. doi:10.1016/j.euromechflu.2022.12.014.
57. Lannelongue Lc, Aronson HEG, Bateman A, Birney E, Caplan T, Juckes M, McEntyre J, Morris AD, Reilly G, Inouye M. GREENER principles for environmentally sustainable computational science. Nature Computational Science. 2023;3.0(6):514-521. doi:10.1038/s43588-023-00461-y.
58. Kim J, Kwak S, Lee HG, Hwang Y, Ham S. A maximum principle of the Fourier spectral method for diffusion equations. Electronic Research Archive. 2023;31.0(9):5396-5405. doi:10.3934/era.2023273.
59. Kutz N. Spectral3 [Internet]. 2019. [cited 2026 Feb 11]. Available from: https://www.youtube.com/watch?v=8lGLdnUYkj4.
60. Kutz N. FD 1 [Internet]. 2019. [cited 2026 Feb 11]. Available from: https://www.youtube.com/watch?v=g9xzv7Xe3w4.
61. Kutz N. overcoming [Internet]. 2019. [cited 2026 Feb 11]. Available from: https://www.youtube.com/watch?v=umcxmDX2iVY.
62. Kutz N. Spectral1 [Internet]. 2019. [cited 2026 Feb 11]. Available from: https://www.youtube.com/watch?v=YKDptSCuQGY.
63. Murphy NB, Cherkaev E, Xin J, Zhu J, Golden KM. Spectral analysis and computation of effective diffusivities in space-time periodic incompressible flows. Annals of Mathematical Sciences and Applications. 2017;2.0(1):3-66. doi:10.4310/amsa.2017.v2.n1.a1.
64. Zhang X, Wang Z, Gursul I. Interaction of multiple vortices over a double delta wing. Aerospace Science and Technology. 2016;48.0:291-307. doi:10.1016/j.ast.2015.11.020.
65. Xiao J, Wang L, Boyd J. Post-print archive. Journal of Comutaational Physics. 2015;285.0:208-225.
66. Li Z, Yang M, Zhang Y. A coupled lattice Boltzmann and finite volume method for natural convection simulation. International Journal of Heat and Mass Transfer. 2014;70.0:864-874. doi:10.1016/j.ijheatmasstransfer.2013.11.077.
67. Rinaldi PR, Dari EA, Vénere MJ, Clausse A. A Lattice-Boltzmann solver for 3D fluid simulation on GPU. Simulation Modelling Practice and Theory. 2012;25.0:163-171. doi:10.1016/j.simpat.2012.03.004.
68. Burnett R. Modelling vortex-vortex and vortex-boundary interaction. 2009.
69. Chen S, Doolen G. LATTICE BOLTZMANN METHOD FOR FLUID FLOWS. Annu. Rev. Fluid Mech. 1998;30.0:329-64.
70. Fabris D, Liepmann D, Marcus D. Quantitative experimental and numerical investigation of a vortex ring impinging on a wall. Physics of Fluids. 1996;8.0(10):2640-2649. doi:10.1063/1.869049.
71. Chandrasekharaiah DS, Debnath L. EQUATIONS OF FLUID MECHANICS. Elsevier; Available from: https://linkinghub.elsevier.com/retrieve/pii/B9780121678807500150.
72. . Numerical Solution of the Advection-Diffusion Equation using the Discontinuous Enrichment Method (DEM).
73. . Chapter 3.
74. . Numerical Solution of Advection-Diffusion-Reaction Equations.
75. Howard J. Reviewer. JSS Journal of Statistical Software.67.0. doi:10.18637/jss.v067.b01.
76. Kutz N. overcoming [Internet]. [cited 2026 Feb 11]. Available from: https://www.youtube.com/watch?v=umcxmDX2iVY.
77. 1161283 [Internet]. [cited 2026 Feb 11]. Available from: https://agu.confex.com/agu/fm22/meetingapp.cgi/Paper/1161283.
78. S2590037423000663 [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S2590037423000663.
79. ssostart [Internet]. [cited 2026 Feb 11]. Available from: https://onlinelibrary.wiley.com/action/ssostart?redirectUri=\%2Fdoi\%2Ffull\%2F10.1002\%2Fenv.70079\%3Fsaml\_referrer.
80. S2590037423000663 [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S2590037423000663?ref=pdf\_download\&fr=RR-2\&rr=9cc649013a5a48b8.
81. 350875965_A_spatial_local_method_for_solving_2D_and_3D_advection-diffusion_equations [Internet]. [cited 2026 Feb 11]. Available from: https://www.researchgate.net/publication/350875965\_A\_spatial\_local\_method\_for\_solving\_2D\_and\_3D\_advection-diffusion\_equations.
82. 66bdd115ac105ea17af303e73d4fec449754-v448bk [Internet]. [cited 2026 Feb 11]. Available from: https://bpb-us-e1.wpmucdn.com/blogs.gwu.edu/dist/9/297/files/2018/01/66bdd115ac105ea17af303e73d4fec449754-v448bk.pdf.
83. 2404.18754 [Internet]. [cited 2026 Feb 11]. Available from: https://arxiv.org/pdf/2404.18754.
84. melosh08_kalashnikova [Internet]. [cited 2026 Feb 11]. Available from: https://www.sandia.gov/app/uploads/sites/127/2021/11/melosh08\_kalashnikova.pdf.
85. order [Internet]. [cited 2026 Feb 11]. Available from: https://global-sci.com/csiam-am/order.
86. 144012989 [Internet]. [cited 2026 Feb 11]. Available from: https://files01.core.ac.uk/download/pdf/144012989.pdf?\_\_cf\_chl\_tk=IPACHLogny8G0TTNbnTMucMyFenXwYhN.jsJk8BUWFk-1770590769-1.0.1.1-NNdbqwsScPW74mnTDvO29rnBtUDBl\_ZUvVAKggSihR4.
87. 7801 [Internet]. [cited 2026 Feb 11]. Available from: https://global-sci.com/index.php/csiam-am/article/view/7801.
88. 1 [Internet]. [cited 2026 Feb 11]. Available from: https://pubs.aip.org/aip/acp/issue/1148/1.
89. 144012989 [Internet]. [cited 2026 Feb 11]. Available from: https://files01.core.ac.uk/download/pdf/144012989.pdf?\_\_cf\_chl\_tk=trsdNgCnVuUXrOYh1wa\_8Flcd.ug8xkkKem4NsHDDgw-1770679354-1.0.1.1-yLmVpJfRLntuNHaws8.qxCmM2CPqRIYXSNP3A82ukFM.
90. 080704_TCs_Part_II_Chapter01 [Internet]. [cited 2026 Feb 11]. Available from: \url{https://www.meteo.physik.uni-muenchen.de/\textasciitilde{}roger/Lectures/Tropical\_Cyclones/080704\_TCs\_Part\_II\_Chapter01.pdf}.
91. 1 [Internet]. [cited 2026 Feb 11]. Available from: https://pubs.aip.org/aip/acp/issue/1148/1?\_\_cf\_chl\_tk=l6I3CRcpd9p7KJSKswBRQ5SOcaR8WAlvNcelJsRewDE-1770679336-1.0.1.1-kE9gDf\_lBn1OvBhehxlPY2SEFL\_CdBfBrQUJznJ2ky0.
92. S0045782508002855 [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S0045782508002855?ref=pdf\_download\&fr=RR-2\&rr=9cc649130ed448b8.
93. S0045782508002855 [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S0045782508002855?via=ihub.
94. authorization.oauth2 [Internet]. [cited 2026 Feb 11]. Available from: https://id.elsevier.com/as/authorization.oauth2?platSite=SD\%2Fscience\&additionalPlatSites=GH\%2Fgeneralhospital\%2CMDY\%2Fmendeley\%2CSC\%2Fscopus\%2CRX\%2Freaxys\&scope=openid\%20email\%20profile\%20els\_auth\_info\%20els\_idp\_info\%20els\_idp\_analytics\_attrs\%20els\_sa\_discover\%20urn\%3Acom\%3Aelsevier\%3Aidp\%3Apolicy\%3Aproduct\%3Ainst\_assoc\&response\_type=code\&redirect\_uri=https\%3A\%2F\%2Fwww.sciencedirect.com\%2Fuser\%2Fidentity\%2Flanding\&authType=SINGLE\_SIGN\_IN\&prompt=login\&client\_id=SDFE-v4\&state=retryCounter\%3D0\%26csrfToken\%3Dec5498f9-960d-4a28-8b37-c0ef94587b8d\%26idpPolicy\%3Durn\%253Acom\%253Aelsevier\%253Aidp\%253Apolicy\%253Aproduct\%253Ainst\_assoc\%26returnUrl\%3Dhttps\%253A\%252F\%252Fwww.sciencedirect.com\%252Fscience\%252Farticle\%252Fabs\%252Fpii\%252FS0045782508002855\%253Fvia\%253Dihub\%26prompt\%3Dlogin.
95. deliverInstCredentials [Internet]. [cited 2026 Feb 11]. Available from: https://auth.elsevier.com/ShibAuth/deliverInstCredentials.
96. S0263876224002363 [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S0263876224002363.
97. Lecture05 [Internet]. [cited 2026 Feb 11]. Available from: \url{https://sites.fem.unicamp.br/\textasciitilde{}phoenics/SITE\_PHOENICS/Apostilas/CFD-1\_U\%20Michigan\_Hong/Lecture05.pdf}.
98. premium-announcement [Internet]. [cited 2026 Feb 11]. Available from: https://languagetool.org/webextension/premium-announcement?type=background\_tab\&utm\_campaign=addon2-trial-page.
99. 2506.05081 [Internet]. [cited 2026 Feb 11]. Available from: https://arxiv.org/pdf/2506.05081.
100. item [Internet]. [cited 2026 Feb 11]. Available from: https://news.ycombinator.com/item?id=44838661.
101. introduction-to-ansys-apdl-programming-easy-hand-on-bar-example-of-learning-apdl-8f584e1be5f7 [Internet]. [cited 2026 Feb 11]. Available from: https://a5833959.medium.com/introduction-to-ansys-apdl-programming-easy-hand-on-bar-example-of-learning-apdl-8f584e1be5f7.
102. ansys-apdl-code-example [Internet]. [cited 2026 Feb 11]. Available from: https://www.scribd.com/document/50005310/ansys-apdl-code-example.
103. S1569190X1200038X [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S1569190X1200038X?ref=pdf\_download\&fr=RR-2\&rr=9cc6493998aede7d.
104. S0017931013010417 [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S0017931013010417?ref=pdf\_download\&fr=RR-2\&rr=9cc6493998b1de7d.
105. books [Internet]. [cited 2026 Feb 11]. Available from: https://books.google.co.uk/books?hl=en\&lr=\&id=kUEoDwAAQBAJ\&oi=fnd\&pg=PA25\&ots=804l4jr4Gt\&sig=Dz44Dj2KiC57KnlLxdKhMF4Krgs\&redir\_esc=y\#v=onepage\&q\&f=false.
106. annurev.fluid.30.1.329 [Internet]. [cited 2026 Feb 11]. Available from: https://www.annualreviews.org/content/journals/10.1146/annurev.fluid.30.1.329.
107. S0029549323000080 [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S0029549323000080?ref=pdf\_download\&fr=RR-2\&rr=9cc6493998adde7d.
108. pdf [Internet]. [cited 2026 Feb 11]. Available from: https://iopscience.iop.org/article/10.1088/1367-2630/ab1bb5/pdf.
109. S1270963815003648 [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S1270963815003648?ref=pdf\_download\&fr=RR-2\&rr=9cc6493b3cb9de7d.
110. S1270963815003648 [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S1270963815003648.
111. 19222 [Internet]. [cited 2026 Feb 11]. Available from: https://discovery.ucl.ac.uk/id/eprint/19222/1/19222.pdf.
112. chapter3 [Internet]. [cited 2026 Feb 11]. Available from: https://people.bath.ac.uk/jhpd20/teaching/fluids/chapter3.pdf.
113. 1328flan [Internet]. [cited 2026 Feb 11]. Available from: https://www.maths.dur.ac.uk/lms/106/talks/1328flan.pdf.
114. Dam2023_Viscous_merging_3_vort [Internet]. [cited 2026 Feb 11]. Available from: https://rucforsk.ruc.dk/ws/portalfiles/portal/87924215/Dam2023\_Viscous\_merging\_3\_vort.pdf.
115. chpthree.PDF [Internet]. [cited 2026 Feb 11]. Available from: \url{https://math.nyu.edu/\textasciitilde{}childres/chpthree.PDF}.
116. E2BD59CDE6BA9052BED8FF9B20A71025 [Internet]. [cited 2026 Feb 11]. Available from: https://www.cambridge.org/core/journals/journal-of-fluid-mechanics/article/vortices-over-bathymetry/E2BD59CDE6BA9052BED8FF9B20A71025.
117. A-spatial-local-method-for-solving-2D-and-3D-advection-diffusion-equations [Internet]. [cited 2026 Feb 11]. Available from: https://www.researchgate.net/publication/350875965\_A\_spatial\_local\_method\_for\_solving\_2D\_and\_3D\_advection-diffusion\_equations/fulltext/6077af3f907dcf667b9d39bb/A-spatial-local-method-for-solving-2D-and-3D-advection-diffusion-equations.pdf?origin=publication\_detail\&\_tp=eyJjb250ZXh0Ijp7ImZpcnN0UGFnZSI6InB1YmxpY2F0aW9uIiwicGFnZSI6InB1YmxpY2F0aW9uRG93bmxvYWQiLCJwcmV2aW91c1BhZ2UiOiJwdWJsaWNhdGlvbiJ9fQ\&\_\_cf\_chl\_tk=PhzEL1zL\_6YajW\_UzCWqJVM9Z9W1ptxu6xYZL4eMxcU-1770656816-1.0.1.1-1O3EJU2d14T7EoixlF0jAGGvW5ZRfzDSG2mQ4hQrLjw.
118. S2590037423000663 [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S2590037423000663?ref=pdf\_download\&fr=RR-2\&rr=9cc6495b38d4d56f.
119. era-31-09-273 [Internet]. [cited 2026 Feb 11]. Available from: https://www.aimspress.com/aimspress-data/era/2023/9/PDF/era-31-09-273.pdf.
120. S0263876224002363 [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S0263876224002363?ref=pdf\_download\&fr=RR-2\&rr=9cc649617a96d56f.
121. S2590037423000663 [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S2590037423000663?\_\_cf\_chl\_rt\_tk=3vmcD61f6wLCJ2vgFtS.R2hTyTtMeIY0YvZP8VovTFw-1770655790-1.0.1.1-801bEQoKN.fjyDj6a9IsG5JjErQYw5EwQTMfvMZxuEc.
122. S1569190X1200038X [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S1569190X1200038X?via\%3Dihub.
123. S0017931013010417 [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S0017931013010417?via\%3Dihub.
124. S0029549323000080#sec2 [Internet]. [cited 2026 Feb 11]. Available from: https://www.sciencedirect.com/science/article/pii/S0029549323000080\#sec2.
125. endnote.com [Internet]. [cited 2026 Feb 11]. Available from: https://endnote.com/?srsltid=AfmBOor0KxRx\_JWS2UWsDdAVm6O8AOA82ednmeVG-fiKntitpSAu5MQ2.
126. free-trial [Internet]. [cited 2026 Feb 11]. Available from: https://endnote.com/free-trial/.
127. s43588-023-00461-y [Internet]. [cited 2026 Feb 11]. Available from: https://www.nature.com/articles/s43588-023-00461-y.
128. 2510.17885 [Internet]. [cited 2026 Feb 11]. Available from: https://www.arxiv.org/pdf/2510.17885.
129. cfd5 [Internet]. [cited 2026 Feb 11]. Available from: \url{https://web.math.princeton.edu/\textasciitilde{}weinan/papers/cfd5.pdf}.
130. Kutz J. Data-Driven Modeling \& Scientific Computation Methods for Integrating Dynamics of Complex Systems and Big Data. Available from: https://faculty.washington.edu/kutz/kutz\_book\_v2.pdf.
131. C.P A, Akaolisa C, S.M.O O. https://www.researchgate.net/publication/352160233\_Analytical\_Effects\_of\_Torsion\_on\_Timber\_Beams [Internet]. [cited 2026 Feb 11]. Available from: https://www.researchgate.net/publication/352160233\_Analytical\_Effects\_of\_Torsion\_on\_Timber\_Beams.

