# Repository Cleanup Plan - MECH0020 Tsunami Vortex Analysis

**Branch**: `copilot/clean-up-repo-file-system`  
**Base Commit**: 3724f71  
**Current Commit**: f3c5c90  
**Date**: 2026-02-06  

---

## Executive Summary

The repository contains substantial clutter from the refactoring process (PR #3, #4). This plan consolidates:
- **14 redundant markdown files** in root (refactoring artifacts)
- **6 test files** scattered in root that belong in `tests/`
- **1 duplicate Analysis file** (Analysis_New.m is redundant)
- **3 large generated files** that should be gitignored (8.5 MB chat.json, etc.)
- **Inconsistent directory structure** that needs reorganization

**Target**: Clean, professional repository structure aligned with MECH0020_COPILOT_AGENT_SPEC.md requirements.

---

## Current State Analysis

### Root Directory Issues (21 files)
```
PROBLEM: Root is cluttered with refactoring artifacts and test files
├── AGENT_EXECUTION_SUMMARY.md         ← Refactoring artifact
├── COMPLETION_REPORT.md               ← Refactoring artifact
├── FILES_CREATED.md                   ← Refactoring artifact
├── File_Manifest.md                   ← Refactoring artifact
├── IMPLEMENTATION_SUMMARY.md          ← Refactoring artifact
├── NEW_ARCHITECTURE.md                ← Refactoring artifact
├── QUICK_START_AFTER_FIXES.md         ← Refactoring artifact
├── REGRESSION_FIXES_SUMMARY.md        ← Refactoring artifact
├── Refactoring_Phase1_and_2_Summary.md ← Refactoring artifact
├── COMPREHENSIVE_TEST_SUITE.m         ← Should be in tests/
├── test_method_dispatcher.m           ← Should be in tests/
├── test_refactoring.m                 ← Should be in tests/
├── test_ui.m                          ← Should be in tests/
├── test_ui_startup.m                  ← Should be in tests/
├── verify_regression_fixes.m          ← Should be in tests/
├── TEST_COMPREHENSIVE.py              ← Auxiliary test, wrong location
├── Refactoring_Log.ipynb              ← Development artifact
├── chat.json                          ← 8.5 MB generated file!
├── comprehensive_test_log.txt         ← 64 KB generated log
├── diary                              ← MATLAB autosave (0 bytes)
└── PROJECT_README.md                  ← Should be THE README.md
```

### Scripts/Main Issues
```
PROBLEM: Contains duplicate Analysis file
Scripts/Main/
├── Analysis.m              ← 6627 lines - OLD monolithic version
├── Analysis_New.m          ← 119 lines - MECH0020 compliant dispatcher
├── AdaptiveConvergenceAgent.m
└── run_adaptive_convergence.m
```

**Analysis**:
- `Analysis_New.m` is the new dispatcher-based thin entry point
- `Analysis.m` is the old 6627-line monolith (pre-refactoring)
- The comment in Analysis_New.m says "Keep Analysis.m for backward compatibility"
- **DECISION**: Analysis_New.m should BECOME Analysis.m (replace old with new)

### Scripts Organization Issues
```
CURRENT:
Scripts/
├── Editable/
├── Infrastructure/
├── Main/              ← Mixed purposes (drivers + agents)
├── Methods/           ← Contains solvers AND modes
├── Sustainability/
├── UI/
└── Visuals/

TARGET (per MECH0020 spec):
Scripts/
├── Drivers/           ← Main entry points (Analysis.m, run_adaptive_convergence.m)
├── Solvers/           ← FD/Spectral/FV solver kernels
├── Infrastructure/    ← Keep as-is
├── Plotting/          ← Rename Visuals/ for clarity
├── UI/                ← Keep as-is
├── Sustainability/    ← Keep as-is
└── Editable/          ← Keep as-is
```

### Documentation Organization Issues
```
CURRENT:
docs/
├── 01_ARCHITECTURE/
├── 02_DESIGN/
├── 03_NOTEBOOKS/
├── markdown_archive/
└── OWL_Framework_Design.md

ISSUE: 
- OWL_Framework_Design.md should be IN 01_ARCHITECTURE or 02_DESIGN
- Refactoring markdown artifacts should go to markdown_archive/
- No clear entrypoint documentation
```

### Data/Results Issues
```
CURRENT:
Results/
├── analysis_evolution.csv
├── analysis_evolution.mat
└── analysis_master.csv

ISSUE:
- Results/ is gitignored but contains 3 files committed to git
- No Input/ directory for reference test cases
- No clear data management strategy
```

---

## Target Directory Structure

```
MECH0020-Numerical-Analysis-of-Tsunami-Vortices-on-Ocean-Surfaces/
├── README.md                          ← Main project readme (from PROJECT_README.md)
├── MECH0020_COPILOT_AGENT_SPEC.md    ← Keep (authoritative spec)
├── .gitignore                         ← Update to exclude generated files
│
├── Scripts/
│   ├── Drivers/                       ← Main entry points
│   │   ├── Analysis.m                 ← NEW: Thin MECH0020-compliant dispatcher
│   │   ├── AdaptiveConvergenceAgent.m
│   │   └── run_adaptive_convergence.m
│   │
│   ├── Solvers/                       ← Numerical method kernels
│   │   ├── FD/                        ← Finite Difference components
│   │   │   ├── Finite_Difference_Analysis.m
│   │   │   ├── FD_Evolution_Mode.m
│   │   │   ├── FD_Convergence_Mode.m
│   │   │   ├── FD_ParameterSweep_Mode.m
│   │   │   └── FD_Plotting_Mode.m
│   │   ├── Spectral_Analysis.m
│   │   ├── Finite_Volume_Analysis.m
│   │   ├── Variable_Bathymetry_Analysis.m
│   │   ├── run_simulation_with_method.m
│   │   ├── extract_unified_metrics.m
│   │   └── mergestruct.m
│   │
│   ├── Infrastructure/                ← Keep as-is (utilities, dispatchers, metrics)
│   │   └── (existing 17 files)
│   │
│   ├── Plotting/                      ← Renamed from Visuals/
│   │   └── create_live_monitor_dashboard.m
│   │
│   ├── UI/                            ← Keep as-is
│   │   ├── UIController.m
│   │   └── TEST_UIController.m
│   │
│   ├── Sustainability/                ← Keep as-is
│   │   └── (existing 5 files)
│   │
│   └── Editable/                      ← Keep as-is (user settings)
│       ├── Default_FD_Parameters.m
│       └── Default_Settings.m
│
├── tests/                             ← All test files here
│   ├── Run_All_Tests.m               ← Master test runner (keep)
│   ├── Test_Cases.m                  ← Test data (keep)
│   ├── COMPREHENSIVE_TEST_SUITE.m    ← MOVE from root
│   ├── test_method_dispatcher.m      ← MOVE from root
│   ├── test_refactoring.m            ← MOVE from root
│   ├── test_ui.m                     ← MOVE from root
│   ├── test_ui_startup.m             ← MOVE from root
│   └── verify_regression_fixes.m     ← MOVE from root
│
├── utilities/                         ← Keep as-is (plotting utilities)
│   ├── Plot_Format.m
│   ├── Legend_Format.m
│   ├── Plot_Saver.m
│   └── (other utilities)
│
├── Data/                              ← NEW: Structured data directory
│   ├── Input/                         ← Small reference test cases (versioned)
│   │   └── README.md                  ← Document test case format
│   └── Output/                        ← Generated results (gitignored)
│       ├── Runs/                      ← Per-run outputs
│       ├── Figures/                   ← Generated figures
│       └── Reports/                   ← Generated reports
│
├── docs/                              ← Consolidated documentation
│   ├── README.md                      ← Documentation index
│   ├── 01_ARCHITECTURE/
│   │   ├── REPOSITORY_LAYOUT_AND_FILE_DOCUMENTATION.md
│   │   └── OWL_Framework_Design.md   ← MOVE from docs/
│   ├── 02_DESIGN/
│   │   └── UI_Research_And_Redesign_Plan.md
│   ├── 03_NOTEBOOKS/
│   │   ├── Tsunami_Vortex_Analysis_Complete_Guide.ipynb
│   │   └── UIController_Test_Documentation.ipynb
│   └── markdown_archive/              ← Refactoring history
│       ├── AGENT_EXECUTION_SUMMARY.md              ← MOVE from root
│       ├── COMPLETION_REPORT.md                    ← MOVE from root
│       ├── FILES_CREATED.md                        ← MOVE from root
│       ├── File_Manifest.md                        ← MOVE from root
│       ├── IMPLEMENTATION_SUMMARY.md               ← MOVE from root
│       ├── NEW_ARCHITECTURE.md                     ← MOVE from root
│       ├── QUICK_START_AFTER_FIXES.md              ← MOVE from root
│       ├── REGRESSION_FIXES_SUMMARY.md             ← MOVE from root
│       ├── Refactoring_Phase1_and_2_Summary.md     ← MOVE from root
│       └── Refactoring_Log.ipynb                   ← MOVE from root
│
└── .github/
    └── agents/                        ← Keep as-is
        ├── OWL_MECH0020_custom_agent_v1_2.md
        └── TREN OWL.agent.md
```

---

## Detailed Action Plan

### PHASE 1: Delete Generated/Temporary Files

**Rationale**: Remove files that are outputs, not source code.

```bash
# Large generated files (not part of source)
rm chat.json                        # 8.5 MB chat log
rm comprehensive_test_log.txt       # 64 KB test output
rm diary                            # MATLAB autosave (empty)

# Python test file (auxiliary, not primary)
rm TEST_COMPREHENSIVE.py            # Python test (MATLAB-first repo)
```

**Files to DELETE**: 4 files  
**Impact**: Reduces repo size by ~8.6 MB  

---

### PHASE 2: Create New Directory Structure

**Rationale**: Prepare target directories before moving files.

```bash
# Create new top-level directories
mkdir -p Data/Input
mkdir -p Data/Output/Runs
mkdir -p Data/Output/Figures
mkdir -p Data/Output/Reports

# Create new Scripts subdirectories
mkdir -p Scripts/Drivers
mkdir -p Scripts/Solvers/FD

# Rename Visuals to Plotting
git mv Scripts/Visuals Scripts/Plotting
```

**Directories CREATED**: 7 new directories  
**Directories RENAMED**: 1 (Visuals → Plotting)

---

### PHASE 3: Reorganize Scripts/

#### 3A: Move Main Entry Points to Drivers/

```bash
# Move dispatcher and convergence agent
git mv Scripts/Main/Analysis_New.m Scripts/Drivers/Analysis.m
git mv Scripts/Main/AdaptiveConvergenceAgent.m Scripts/Drivers/
git mv Scripts/Main/run_adaptive_convergence.m Scripts/Drivers/

# Delete old monolithic Analysis.m (6627 lines, pre-refactoring)
rm Scripts/Main/Analysis.m
```

**Rationale**:
- `Analysis_New.m` (119 lines) is the MECH0020-compliant thin dispatcher
- Rename it to `Analysis.m` to become the canonical entry point
- Remove old monolithic `Analysis.m` (6627 lines) - it's pre-refactoring legacy code
- `Scripts/Main/` directory becomes empty and can be removed

#### 3B: Reorganize Solvers/ by Method

```bash
# Move FD-specific files to Solvers/FD/
git mv Scripts/Methods/Finite_Difference_Analysis.m Scripts/Solvers/FD/
git mv Scripts/Methods/FD_Evolution_Mode.m Scripts/Solvers/FD/
git mv Scripts/Methods/FD_Convergence_Mode.m Scripts/Solvers/FD/
git mv Scripts/Methods/FD_ParameterSweep_Mode.m Scripts/Solvers/FD/
git mv Scripts/Methods/FD_Plotting_Mode.m Scripts/Solvers/FD/

# Move other method files to Solvers/
git mv Scripts/Methods/Spectral_Analysis.m Scripts/Solvers/
git mv Scripts/Methods/Finite_Volume_Analysis.m Scripts/Solvers/
git mv Scripts/Methods/Variable_Bathymetry_Analysis.m Scripts/Solvers/
git mv Scripts/Methods/run_simulation_with_method.m Scripts/Solvers/
git mv Scripts/Methods/extract_unified_metrics.m Scripts/Solvers/
git mv Scripts/Methods/mergestruct.m Scripts/Solvers/

# Remove empty Methods directory
rmdir Scripts/Methods
```

**Rationale**: Separate solver kernels from infrastructure. FD has 5 related files, so gets a subdirectory.

---

### PHASE 4: Move Test Files to tests/

```bash
# Move all test files from root to tests/
git mv COMPREHENSIVE_TEST_SUITE.m tests/
git mv test_method_dispatcher.m tests/
git mv test_refactoring.m tests/
git mv test_ui.m tests/
git mv test_ui_startup.m tests/
git mv verify_regression_fixes.m tests/
```

**Files MOVED**: 6 test files  
**Rationale**: All testing code should be in `tests/` directory.

---

### PHASE 5: Archive Refactoring Documentation

```bash
# Move refactoring artifacts to docs/markdown_archive/
git mv AGENT_EXECUTION_SUMMARY.md docs/markdown_archive/
git mv COMPLETION_REPORT.md docs/markdown_archive/
git mv FILES_CREATED.md docs/markdown_archive/
git mv File_Manifest.md docs/markdown_archive/
git mv IMPLEMENTATION_SUMMARY.md docs/markdown_archive/
git mv NEW_ARCHITECTURE.md docs/markdown_archive/
git mv QUICK_START_AFTER_FIXES.md docs/markdown_archive/
git mv REGRESSION_FIXES_SUMMARY.md docs/markdown_archive/
git mv Refactoring_Phase1_and_2_Summary.md docs/markdown_archive/
git mv Refactoring_Log.ipynb docs/markdown_archive/

# Move OWL framework design to architecture docs
git mv docs/OWL_Framework_Design.md docs/01_ARCHITECTURE/

# Promote PROJECT_README.md to root README.md
git mv PROJECT_README.md README.md
```

**Files MOVED**: 11 documentation files  
**Rationale**: Historical artifacts belong in archive; user-facing docs at root.

---

### PHASE 6: Update .gitignore

Add generated output directories and files:

```gitignore
# MATLAB autosaves
*.asv
*.autosave

# Compiled MEX files
*.mexw64
*.mexa64
*.mexmaci64

# Generated artefacts
Data/Output/
diary
*.log

# Large generated files
chat.json
comprehensive_test_log.txt

# Python cache
__pycache__/
*.pyc
*.pyo

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Test outputs
tests/test_results.mat

# Legacy Results directory (deprecated)
Results/
```

**Rationale**: Prevent committing generated outputs; use Data/Output/ going forward.

---

### PHASE 7: Fix Import Paths in Code

Files that need path updates:

#### 7A: Scripts/Drivers/Analysis.m

```matlab
% OLD paths:
addpath(fullfile(repo_root, 'Scripts', 'Main'));
addpath(fullfile(repo_root, 'Scripts', 'Methods'));

% NEW paths:
addpath(fullfile(repo_root, 'Scripts', 'Drivers'));
addpath(fullfile(repo_root, 'Scripts', 'Solvers'));
addpath(fullfile(repo_root, 'Scripts', 'Solvers', 'FD'));
```

#### 7B: Scripts/Infrastructure/ModeDispatcher.m

Update dispatcher to look for solvers in new location:

```matlab
% Update paths to find Finite_Difference_Analysis.m, etc.
% in Scripts/Solvers/ and Scripts/Solvers/FD/
```

#### 7C: All test files in tests/

Update test files to reference correct paths:
- `tests/COMPREHENSIVE_TEST_SUITE.m`
- `tests/test_method_dispatcher.m`
- `tests/test_refactoring.m`
- `tests/test_ui.m`
- `tests/test_ui_startup.m`
- `tests/verify_regression_fixes.m`

Common pattern:
```matlab
% Add paths relative to repository root
repo_root = fileparts(fileparts(mfilename('fullpath')));  % Up two levels from tests/
addpath(fullfile(repo_root, 'Scripts', 'Drivers'));
addpath(fullfile(repo_root, 'Scripts', 'Solvers'));
addpath(fullfile(repo_root, 'Scripts', 'Solvers', 'FD'));
addpath(fullfile(repo_root, 'Scripts', 'Infrastructure'));
addpath(fullfile(repo_root, 'Scripts', 'Plotting'));
addpath(fullfile(repo_root, 'utilities'));
```

#### 7D: Scripts/Infrastructure/PathBuilder.m

Update to reference new directory structure:

```matlab
function paths = PathBuilder()
    repo_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    
    paths.root = repo_root;
    paths.drivers = fullfile(repo_root, 'Scripts', 'Drivers');
    paths.solvers = fullfile(repo_root, 'Scripts', 'Solvers');
    paths.solvers_fd = fullfile(repo_root, 'Scripts', 'Solvers', 'FD');
    paths.infrastructure = fullfile(repo_root, 'Scripts', 'Infrastructure');
    paths.plotting = fullfile(repo_root, 'Scripts', 'Plotting');
    paths.utilities = fullfile(repo_root, 'utilities');
    paths.data_input = fullfile(repo_root, 'Data', 'Input');
    paths.data_output = fullfile(repo_root, 'Data', 'Output');
end
```

#### 7E: Update docs/01_ARCHITECTURE/REPOSITORY_LAYOUT_AND_FILE_DOCUMENTATION.md

Update architecture documentation to reflect new structure.

---

### PHASE 8: Handle Results/ Directory

**Issue**: `Results/` is gitignored but contains 3 committed CSV/MAT files.

**Options**:
1. **Delete committed results** - treat as generated outputs
2. **Move to Data/Input/** - treat as reference test data
3. **Move to docs/markdown_archive/** - treat as historical artifacts

**Recommendation**: **Option 1** - Delete them. They are generated outputs from old runs.

```bash
# Remove from git tracking (already gitignored)
git rm -r Results/
```

**Rationale**: These are outputs from previous test runs, not source data. New outputs go to Data/Output/.

---

## Summary Statistics

### Files to DELETE: 5
```
chat.json (8.5 MB)
comprehensive_test_log.txt (64 KB)
diary (0 bytes)
TEST_COMPREHENSIVE.py
Scripts/Main/Analysis.m (old monolithic 6627-line version)
```

### Files to MOVE: 28
```
# To Scripts/Drivers/ (3 files)
Scripts/Main/Analysis_New.m → Scripts/Drivers/Analysis.m
Scripts/Main/AdaptiveConvergenceAgent.m → Scripts/Drivers/
Scripts/Main/run_adaptive_convergence.m → Scripts/Drivers/

# To Scripts/Solvers/FD/ (5 files)
Scripts/Methods/Finite_Difference_Analysis.m
Scripts/Methods/FD_Evolution_Mode.m
Scripts/Methods/FD_Convergence_Mode.m
Scripts/Methods/FD_ParameterSweep_Mode.m
Scripts/Methods/FD_Plotting_Mode.m

# To Scripts/Solvers/ (6 files)
Scripts/Methods/Spectral_Analysis.m
Scripts/Methods/Finite_Volume_Analysis.m
Scripts/Methods/Variable_Bathymetry_Analysis.m
Scripts/Methods/run_simulation_with_method.m
Scripts/Methods/extract_unified_metrics.m
Scripts/Methods/mergestruct.m

# To tests/ (6 files)
COMPREHENSIVE_TEST_SUITE.m
test_method_dispatcher.m
test_refactoring.m
test_ui.m
test_ui_startup.m
verify_regression_fixes.m

# To docs/markdown_archive/ (10 files)
AGENT_EXECUTION_SUMMARY.md
COMPLETION_REPORT.md
FILES_CREATED.md
File_Manifest.md
IMPLEMENTATION_SUMMARY.md
NEW_ARCHITECTURE.md
QUICK_START_AFTER_FIXES.md
REGRESSION_FIXES_SUMMARY.md
Refactoring_Phase1_and_2_Summary.md
Refactoring_Log.ipynb

# To docs/01_ARCHITECTURE/ (1 file)
docs/OWL_Framework_Design.md

# To root (1 file)
PROJECT_README.md → README.md
```

### Directories to CREATE: 7
```
Data/Input/
Data/Output/Runs/
Data/Output/Figures/
Data/Output/Reports/
Scripts/Drivers/
Scripts/Solvers/
Scripts/Solvers/FD/
```

### Directories to RENAME: 1
```
Scripts/Visuals/ → Scripts/Plotting/
```

### Directories to DELETE: 2
```
Scripts/Main/ (after moving all contents)
Scripts/Methods/ (after moving all contents)
Results/ (gitignored outputs)
```

### Files to UPDATE: ~15
```
Scripts/Drivers/Analysis.m (path updates)
Scripts/Infrastructure/ModeDispatcher.m (solver paths)
Scripts/Infrastructure/PathBuilder.m (new directory structure)
Scripts/Infrastructure/initialize_directory_structure.m (use Data/Output/)
tests/*.m (6 files - path updates)
docs/01_ARCHITECTURE/REPOSITORY_LAYOUT_AND_FILE_DOCUMENTATION.md
.gitignore (add Data/Output/, chat.json, etc.)
README.md (ensure correct quickstart paths)
```

---

## Verification Checklist

After cleanup, verify:

- [ ] `Analysis.m` is in `Scripts/Drivers/` and is the 119-line dispatcher version
- [ ] Old 6627-line Analysis.m is deleted
- [ ] All test files are in `tests/`
- [ ] All refactoring markdown is in `docs/markdown_archive/`
- [ ] Root has only: README.md, MECH0020_COPILOT_AGENT_SPEC.md, .gitignore
- [ ] `Scripts/Methods/` and `Scripts/Main/` directories don't exist
- [ ] `Scripts/Drivers/`, `Scripts/Solvers/`, `Scripts/Solvers/FD/` exist
- [ ] `Scripts/Visuals/` renamed to `Scripts/Plotting/`
- [ ] `Data/Input/` and `Data/Output/` directories exist
- [ ] Tests run successfully: `tests/Run_All_Tests.m`
- [ ] UI launches successfully: `Scripts/Drivers/Analysis.m` in UI mode
- [ ] No uncommitted generated files (chat.json, diary, etc.)
- [ ] .gitignore properly excludes Data/Output/
- [ ] Repository size reduced by ~8.6 MB

---

## Risk Assessment

### Low Risk
- Moving test files to tests/ (isolated, no dependencies)
- Archiving markdown documentation (no code impact)
- Deleting generated files (not source code)

### Medium Risk
- Renaming Analysis_New.m → Analysis.m (main entry point)
  - **Mitigation**: It's already the intended new entry point
  - **Validation**: Run UI and standard modes after change

### High Risk
- Reorganizing Scripts/Methods/ → Scripts/Solvers/
  - **Impact**: Affects ModeDispatcher, all test files, Analysis.m
  - **Mitigation**: Use git mv to preserve history; update paths systematically
  - **Validation**: Run comprehensive test suite after changes

---

## Implementation Order (Recommended)

1. **Phase 1** (Delete generated files) - Low risk, immediate repo size reduction
2. **Phase 2** (Create directories) - Zero risk, preparation
3. **Phase 4** (Move test files) - Low risk, isolated
4. **Phase 5** (Archive docs) - Low risk, no code impact
5. **Phase 3A** (Move Drivers/) - Medium risk, critical path
6. **Phase 6** (Update .gitignore) - Low risk
7. **Phase 7** (Fix paths) - High risk, must be done carefully
8. **Phase 3B** (Reorganize Solvers/) - High risk, after path fixes ready
9. **Phase 8** (Handle Results/) - Low risk
10. **VERIFICATION** - Run all tests, UI, convergence agent

---

## Post-Cleanup Maintenance

### New File Placement Rules

**Entry points / Main scripts**:  
→ `Scripts/Drivers/`

**Solver kernels / Numerical methods**:  
→ `Scripts/Solvers/` (or `Scripts/Solvers/FD/` if FD-specific)

**Infrastructure / Utilities**:  
→ `Scripts/Infrastructure/`

**Visualization code**:  
→ `Scripts/Plotting/`

**Test code**:  
→ `tests/`

**Documentation**:  
→ `docs/01_ARCHITECTURE/`, `docs/02_DESIGN/`, or `docs/03_NOTEBOOKS/`

**Historical artifacts**:  
→ `docs/markdown_archive/`

**Reference test data (small, versioned)**:  
→ `Data/Input/`

**Generated outputs (gitignored)**:  
→ `Data/Output/`

---

## Expected Benefits

1. **Clearer project structure** - Logical separation of concerns
2. **Reduced repository size** - 8.6 MB smaller (chat.json removal)
3. **Better onboarding** - New users see README.md, not 14 markdown files
4. **Easier testing** - All test files in one location
5. **Historical clarity** - Refactoring artifacts archived, not deleted
6. **Compliance with spec** - Matches MECH0020_COPILOT_AGENT_SPEC.md requirements
7. **Professional appearance** - Clean root, organized subdirectories

---

## Open Questions / Decisions Needed

1. **Results/ directory CSV/MAT files**: Delete or archive?  
   **Recommendation**: Delete (they're generated outputs)

2. **utilities/ directory**: Keep at root or move to Scripts/?  
   **Recommendation**: Keep at root (plotting utilities are cross-cutting)

3. **README.md content**: Use PROJECT_README.md as-is or enhance?  
   **Recommendation**: Use as-is, enhance in separate PR

4. **Data/Input/ test cases**: Should we create example input files?  
   **Recommendation**: Add in separate PR after cleanup

---

## Approval and Next Steps

**This plan is ready for:**
1. Review by repository owner
2. Execution by agent (following implementation order)
3. Verification via test suite
4. Pull request to main branch

**Estimated effort**: 2-3 hours (mostly path updates and testing)

**Estimated lines of code changed**: ~50-100 (path updates in ~15 files)

---

**Plan Author**: MECH0020 Copilot Agent  
**Plan Date**: 2026-02-06  
**Status**: DRAFT - Awaiting Approval
