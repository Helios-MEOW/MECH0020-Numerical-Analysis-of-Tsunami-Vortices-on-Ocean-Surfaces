# UI Rebuild + Repo Cleanup TODO (February 2026)

## SWEEP PHASE

- [x] Sweep 1: Inventory repo structure and identify UI-related files to reset
- [x] Sweep 2: Search for merge conflicts, unclosed delimiters, and naming collisions (no conflicts found)
- [x] Sweep 3: Run error checks across MATLAB + Python UI components (UIController.m now clean)

## MATLAB UI RECONSTRUCTION

- [x] Rebuild MATLAB UIController from the ground up (3 tabs: Configuration, Live Monitor, Results)
- [x] Map UI controls directly to Analysis.m parameters (Nx, Ny, delta, dt, Tfinal, nu, etc.)
- [x] Add explicit note: ? = ?x = ?y (domain discretization)
- [x] Add method-driven UI logic (control visibility based on analysis method)
- [x] Add mode-driven UI logic (evolution/convergence/sweep/animation/experimentation)
- [x] Build grouped, compact input layout with consistent sizing
- [x] Add Simulation Settings group (figure saving, animation settings)
- [x] Remove sustainability output directory input (use predefined paths)
- [x] Add convergence panel with LaTeX rendering via HTML/MathJax
- [x] Add IC preview with inline IC formulas (no Scripts/Initial_Conditions dependency)
- [x] Add boundary conditions summary (periodic for finite difference)
- [x] Add periodic boundary visualization in IC preview (visual boundary box)
- [x] Add readiness checklist with red/green status lights
- [x] Add MATLAB terminal capture (diary-based, auto-refresh)
- [x] Define on_off() and bool_to_color() helper methods
- [x] Remove stale references (browse_energy_dir, bathy_coupling, ic_* fields)
- [x] Fix all code analyzer warnings (UIController.m error-free)

## LIVE MONITOR & RESULTS

- [x] Live Monitor tab: execution monitor + convergence monitor + MATLAB terminal output
- [x] Live Monitor: pre-populated placeholder plots (iterations vs time, iter/sec vs time)
- [x] Live Monitor: progress bar + metrics (elapsed time, grid, dt, nu, sustainability)
- [x] Convergence monitor: mode-aware messaging + LaTeX criteria text
- [x] Results/Figures tab: dropdown + tabbed figure gallery (50+ figures supported)
- [x] Results/Figures: integrate metrics text area (history + display)
- [x] Add add_figure(), refresh_figures(), show_figure() helpers

## UI BEHAVIOR & CONFIGURATION

- [x] Ensure UI does not overwrite default script settings (only applies when user exports)
- [x] Retain startup option to skip UI and use existing configuration
- [x] Add startup dialog (UI Mode vs Traditional Mode)
- [x] Implement launch_simulation() to collect config and store via setappdata()

## QT UI UPDATES

- [ ] Rebuild Qt UI to match MATLAB UI structure and parameter map
- [ ] Remove deprecated UI logic and unused widgets from Qt app
- [ ] Align Qt IC preview with domain size, grid size, and vortex pattern

## REPO CLEANUP & OPTIMIZATION

- [ ] Sweep for unused/redundant scripts in Scripts/ and utilities/
- [ ] Consolidate utility functions (Plot_Defaults, Plot_Format, etc.)
- [ ] Check for dangling references to removed Initial_Conditions/ folder
- [ ] Normalize file naming and folder structure
- [ ] Document performance bottlenecks and refactor candidates
- [ ] Generate code dependency map (which scripts call which)

## FINAL VALIDATION

- [ ] Manual test: Launch UIController and verify all tabs/controls render
- [ ] Manual test: Verify IC preview updates with all IC types
- [ ] Manual test: Verify terminal capture works (diary-based output)
- [ ] Manual test: Verify configuration export/import works
- [ ] Run comprehensive linter on Python codebase
- [ ] Run error checks on all .m files
- [ ] Run final repo-wide checks (conflicts, syntax, missing references)
- [ ] Update documentation with new UI workflow
