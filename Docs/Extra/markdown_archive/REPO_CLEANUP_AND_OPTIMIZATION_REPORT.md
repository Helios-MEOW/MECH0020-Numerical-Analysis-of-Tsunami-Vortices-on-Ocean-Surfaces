# Repo Cleanup & Optimization Report

## SCRIPTS DIRECTORY OVERVIEW (22 .m files)

### Core Simulation
- Scripts/Main/Analysis.m (510 lines) - MAIN DRIVER: parameter validation, mode dispatch, metric collection
- Scripts/Main/AdaptiveConvergenceAgent.m - Convergence study automation

### Methods (4 + 2 dispatcher)
- Finite_Difference_Analysis.m - Primary method (unchanged per user)
- Finite_Volume_Analysis.m - Primary method (unchanged per user)
- Spectral_Analysis.m - Primary method (unchanged per user)
- Variable_Bathymetry_Analysis.m - Primary method (unchanged per user)
- run_simulation_with_method.m - Dispatcher wrapper
- run_simulation_with_method.m - Unified dispatcher (consolidated from enhanced version)
- extract_unified_metrics.m - Post-processing utility
- mergestruct.m - Struct utility (name conflicts: check if used elsewhere)

### Infrastructure (4 utilities)
- create_default_parameters.m - Default config factory
- validate_simulation_parameters.m - Input validation
- initialize_directory_structure.m - Setup Results/ and Logs/
- ic_factory.m - Initial condition factory (REFERENCE ONLY; not used by UIController)
- disperse_vortices.m - Vortex placement for multi-vortex patterns

### UI (2 files)
- UIController.m (1340 lines) - REBUILT: 3-tab interface with terminal capture
- TEST_UIController.m - Test/demo script

### Sustainability (4 files)
- EnergySustainabilityAnalyzer.m - Energy tracking (optional, requires external hardware bridge)
- HardwareMonitorBridge.m - Hardware interface (optional)
- iCUEBridge.m - RGB lighting bridge (optional)
- update_live_monitor.m - Monitor update callback

### Visuals (1 file)
- create_live_monitor_dashboard.m - Dashboard generation (optional, uses Sustainability outputs)

## UTILITIES DIRECTORY OVERVIEW (7 .m files)

- Plot_Format.m - Figure formatting (used by visualization code)
- Plot_Format_And_Save.m - Combined format + save (alternative to Plot_Saver)
- Plot_Saver.m - Figure saving (handles multiple formats)
- Plot_Defaults.m - Default plot parameters
- Legend_Format.m - Legend styling
- estimate_data_density.m - Data visualization helper
- display_function_instructions.m - Help display utility

## OPTIMIZATION OPPORTUNITIES

### High Priority
1. **Duplicated Plotting Code**: Plot_Format, Plot_Format_And_Save, Plot_Saver overlap
   - Recommendation: Consolidate into single Plot_Manager.m with API for format + save + default
   - Impact: Reduces maintenance, clarifies intent
   
2. **Convergence Study Dispatch**: AdaptiveConvergenceAgent may overlap with Analysis.m mode='convergence'
   - Recommendation: Review integration or mark one as deprecated
   - Status: Needs investigation

3. **Terminal Capture**: UIController uses MATLAB diary; may conflict with user scripts
   - Recommendation: Use separate diary file; clean up on shutdown
   - Status: IMPLEMENTED in UIController.m (diary_file = fullfile(tempdir, 'ui_controller_terminal.log'))

### Medium Priority
1. **IC Factory**: Inlined in UIController.m; ic_factory.m is reference-only
   - Recommendation: Keep ic_factory.m as documentation; consider moving ic_factory logic to Methods or Infrastructure if needed for Analysis.m direct calls
   
## UNIFIED: Method Dispatchers
   - **Status**: RESOLVED - run_simulation_with_method_enhanced.m has been merged into run_simulation_with_method.m
   - Both versions now consolidated into single dispatcher with comprehensive metrics extraction
   - Status: Kept separate per user's "do not modify method scripts" constraint

3. **Validation Logic**: validate_simulation_parameters.m used by Analysis.m
   - Recommendation: Consider folding into Analysis.m or creating shared validation module
   - Impact: Reduces file count, clarifies dependencies

### Low Priority
1. **Utilities Naming**: No 'obj' prefix or clear categorization
   - Recommendation: Add prefix or rename folder to utilities_plotting or utilities_visualization
   
2. **Sustainability Optional**: If not always used, wrap in optional feature check
   - Recommendation: Add try-catch in Analysis.m for Sustainability imports

## DEPENDENCY MAP

Analysis.m depends on:
- create_default_parameters.m (defaults)
- validate_simulation_parameters.m (validation)
- initialize_directory_structure.m (setup)
- Finite_Difference_Analysis.m / Finite_Volume_Analysis.m / Spectral_Analysis.m (methods)
- AdaptiveConvergenceAgent.m (convergence study mode)
- extract_unified_metrics.m (metrics)
- Sustainability/* (optional energy tracking)
- Plot_Saver.m (optional visualization)

UIController.m depends on:
- disperse_vortices.m (optional, multi-vortex IC placement)
- create_default_parameters.m (for config defaults)
- No dependency on Initial_Conditions/ folder (successfully inlined IC formulas)

## MISSING/DEPRECATED ITEMS

- Initial_Conditions/ folder: REMOVED - UIController now inlines all IC formulas 
- ic_elliptical_vortex.m, ic_lamb_oseen.m, etc.: INLINED into UIController.m 
- energy_dir UI field: REMOVED per user spec 
- browse_energy_dir callback: REMOVED 

## RECOMMENDED CLEANUP ACTIONS

[ ] 1. Review AdaptiveConvergenceAgent.m - mark as primary or secondary
[ ] 2. Consolidate plotting utilities (Plot_Format.m + Plot_Format_And_Save.m + Plot_Saver.m)
[x] 3. Verified and unified run_simulation_with_method.m vs run_simulation_with_method_enhanced.m
   - Enhanced version merged into base version
   - Enhanced file deleted after consolidation
   - Metrics extraction now unified across all methods
[ ] 4. Add optional feature flags for Sustainability/* in Analysis.m
[ ] 5. Rename utilities/ -> utilities_plotting/ or add module prefixes
[ ] 6. Document method dispatcher flow and convergence study workflow
[ ] 7. Add static dependency graph visualization to docs/

