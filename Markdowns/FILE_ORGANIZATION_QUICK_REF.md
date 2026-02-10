# Quick Reference: File Organization

## Where Your Figures Are Saved

### Evolution Mode Results
```
Figures/Finite Difference/EVOLUTION/
├── Evolution/        → Time-evolution plots (vorticity maps over time)
├── Contour/          → Contour-only visualizations
└── Vectorised/       → Vector field visualizations
```

### Convergence Study Results
```
Figures/Finite Difference/CONVERGENCE/
└── Convergence/
    ├── Phase_Coarse/                      → Initial coarse grid phase
    ├── Phase_Bracketing/                  → Bracketing phase
    ├── Phase_BinarySearch/                → Binary search phase
    └── Phase_FinalValidation/             → Final validation phase
    
    Each phase contains: TIMESTAMP_N####_Nx_Ny/
    ├── conv_phaseN_iter####_N####_Evolution.png
    ├── conv_phaseN_iter####_N####_Contour.png
    └── conv_phaseN_iter####_N####_Vectorised.png
```

### Parameter Sweep Results
```
Figures/Finite Difference/SWEEP/
├── Evolution/        → Evolution plots for each parameter combination
├── Contour/          → Contour plots for each parameter combination
└── Vectorised/       → Vector field plots for each parameter combination
```

### Animation Results
```
Figures/Animations/
├── EVOLUTION/        → High-quality animations for evolution runs
├── CONVERGENCE/      → Converged mesh animations (final, high-quality)
└── SWEEP/            → Parameter sweep animations
```

## Filename Breakdown

### Standard Case Figure
```
EVOLUTION_20260127_143522_Nx=128_Ny=128_nu=1.00e-06_dt=1.00e-02_Tfinal=1.0_ic=stretched_gaussian_coeff[1.00,2.00]_Evolution.png
│        │      │        │  │    │  │                                                                          │
│        │      │        │  │    │  └─ Figure Type (Evolution/Contour/Vectorised)
│        │      │        │  │    └─ Timestamp in compact format
│        │      │        │  └─ Grid size in Y dimension
│        │      │        └─ Grid size in X dimension
│        │      └─ Date (YYYYMMDD)
│        └─ Time (HHMMSS)
└─ Operational Mode (EVOLUTION/CONVERGENCE/SWEEP/ANIMATION)
```

### Convergence Iteration Figure
```
conv_coarse_iter0005_N0512_Contour.png
│    │     │    │    │    │
│    │     │    │    │    └─ Figure Type
│    │     │    │    └─ Grid Resolution (N value)
│    │     │    └─ Iteration Number (4 digits)
│    │     └─ Keyword: "iter"
│    └─ Convergence Phase Name
└─ Prefix: "conv" (convergence iteration figure)
```

## Finding Your Results

### By Mode
```matlab
% All EVOLUTION results
cd Figures/Finite\ Difference/EVOLUTION/

% All CONVERGENCE results
cd Figures/Finite\ Difference/CONVERGENCE/

% All SWEEP results
cd Figures/Finite\ Difference/SWEEP/
```

### By Figure Type
```matlab
% All contour plots from evolution
cd Figures/Finite\ Difference/EVOLUTION/Contour/

% All vector field plots from sweep
cd Figures/Finite\ Difference/SWEEP/Vectorised/
```

### By Timestamp (Most Recent First)
```matlab
% Files naturally sort chronologically
cd Figures/Finite\ Difference/EVOLUTION/Evolution/
ls -t *.png | head -10  % 10 most recent evolution files
```

### By Parameter
```matlab
% All files with specific viscosity
grep -r "nu=1.00e-06" Figures/

% All convergence files with specific grid resolution
grep -r "N0512" Figures/Finite\ Difference/CONVERGENCE/
```

## Key Differences from Previous Version

| Aspect | Old Format | New Format |
|--------|-----------|-----------|
| **Mode Identification** | Not in filename | Prefix: EVOLUTION/CONVERGENCE/SWEEP |
| **Timestamp Format** | 2026-01-27_14-35-22 | 20260127_143522 |
| **Grid Resolution** | Not in filename | Nx=128_Ny=128 |
| **Directory Structure** | No mode separation | Separate MODE folders |
| **File Sorting** | Random order | Chronological (YYYYMMDD) |
| **Parameter Discovery** | Requires config lookup | All in filename |

## Configuration

To change figure storage location or format, edit the configurable section in Analysis.m:

```matlab
% ── FIGURE & ANIMATION EXPORT ───────────────────────────────────────────
figures.root_dir = "Figures";              % Root directory
figures.save_png = true;                   % Save as PNG?
figures.save_fig = false;                  % Save as MATLAB .fig?
figures.dpi = 300;                         % Resolution (DPI)
figures.close_after_save = true;           % Close figure window after save?
convergence.save_iteration_figures = true; % Save convergence iteration figures?
```

## Troubleshooting

**Q: I can't find my evolution results**  
A: Check `Figures/Finite Difference/EVOLUTION/[Evolution|Contour|Vectorised]/`

**Q: Files don't have mode names (old format)**  
A: These are results from before the file organization update. Old files remain in their original locations.

**Q: Where's the animation from convergence?**  
A: In `Figures/Animations/CONVERGENCE/` with timestamp in filename (not in a versioned subfolder).

**Q: How do I find a specific parameter sweep result?**  
A: Check `Figures/Finite Difference/SWEEP/` and search for the viscosity value in filenames:
```bash
grep "nu=1.00e-05" Figures/Finite\ Difference/SWEEP/Evolution/*.png
```
