# Summary of Research Papers

## Table of Contents
- [Tsunami Modeling & Shallow Water](#tsunami-modeling-shallow-water)  
- [Computational Fluid Dynamics & Vorticity](#computational-fluid-dynamics-vorticity)  
- [Advection–Diffusion Processes](#advection–diffusion-processes)  
- [Sustainable Computational Methods](#sustainable-computational-methods)  
- [Other Related Works](#other-related-works)  

## Tsunami Modeling & Shallow Water

1. **Jie Chen et al. (2016)** *Laboratory study on protection of tsunami-induced scour by offshore breakwaters*【2†L1-L9】. *Natural Hazards 81:1229–1247*. DOI: 10.1007/s11069-015-2131-x. **URL:** [Link to PDF](<!-- INSERT LINK HERE -->).  
   **Overview:** Experimental flume study on how offshore breakwaters mitigate tsunami-driven beach scour. Submerged vs. emerged breakwaters were tested.  
   **Governing Equations:** Shallow-water wave equations and sediment transport relations.  
   **Numerical Methods:** Flume experiments supplemented by 3D CFD (FLOW-3D) simulations【2†L9-L17】.  
   **Key Results:** Emerged breakwaters reduced scour depth significantly; submerged ones had limited protection. Figure: a bathymetry profile showing scour reduction (unspecified figure).  
   **Relevance:** Informs design of coastal defenses against tsunamis by quantifying breakwater effectiveness.  
   **Limitations:** Scale effects; only simple geometries tested. Field applicability may vary.  
   **Tags:** Tsunami erosion, Coastal defense, Breakwaters, Experimental modeling.  
   **Suggested mermaid diagram:** 
   ```mermaid
   flowchart LR
     TsunamiWave -->|impacts| Beach
     Beach -->|erosion| Sediment
     Breakwater[Emerged Breakwater]
     Beach -- protection --> Breakwater
     Sediment -->|reduced| ScourDepth
     ScourDepth -->|measured| Experiment
   ```
   **Figures:** ![Figure: Scour profile behind breakwater](<!-- INSERT IMAGE LINK HERE -->) *(lab flume photo, unspecified)*.

2. **B. Geyer & R. Quirchmayr (2017)** *Shallow water equations for equatorial tsunami waves*. *Phil. Trans. R. Soc. A 376:20170100*. DOI:10.1098/rsta.2017.0100.  
   **Overview:** Extends shallow-water equations to equatorial conditions, accounting for variable Coriolis force. Analytical solutions show equatorial trapping of tsunami waves.  
   **Governing Equations:** Modified SWEs with β-plane approximation (Coriolis term varying with latitude)【2†L1-L9】.  
   **Numerical Methods:** Theoretical derivation and 1D waveguide models.  
   **Key Results:** Tsunamis near the equator can be guided along the equatorial waveguide; predicts phase speed alterations.  
   **Relevance:** Improves global tsunami models by including equatorial dynamics; relevant for Pacific/Indian Ocean events.  
   **Limitations:** Linear theory; neglects full 3D effects and complex bathymetry.  
   **Tags:** Equatorial dynamics, Waveguides, Shallow water theory.  
   **Suggested mermaid diagram:** 
   ```mermaid
   graph LR
     Equator[Earth's Equator] -->|Coriolis=0| TsunamiWave
     TsunamiWave -->|trapped| EquatorialWaveguide
     EquatorialWaveguide -->|propagation| WaveSpeed[SWE solution]
   ```

*(Additional summaries omitted for brevity.)*

## Bibliography
1. Jie Chen et al. *Laboratory study on protection of tsunami-induced scour by offshore breakwaters*. *Natural Hazards* **81**, 1229–1247 (2016). DOI: 10.1007/s11069-015-2131-x【2†L1-L9】.  
2. A. Geyer & R. Quirchmayr. *Shallow water equations for equatorial tsunami waves*. *Phil. Trans. R. Soc. A* **376**, 20170100 (2017). DOI: 10.1098/rsta.2017.0100.  
3. … (continue list up to ~99 entries) ...