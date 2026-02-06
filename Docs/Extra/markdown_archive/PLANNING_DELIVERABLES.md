# Repository Cleanup Planning - Deliverables

**Task**: Audit repository and create detailed cleanup plan  
**Branch**: `copilot/clean-up-repo-file-system`  
**Date**: 2026-02-06  
**Status**: ✅ PLANNING COMPLETE

---

## Deliverables Summary

### 5 Documents Created

| # | Document | Lines | Size | Purpose |
|---|----------|-------|------|---------|
| 1 | **CLEANUP_INDEX.md** | 257 | 6.7 KB | Navigation hub for all cleanup docs |
| 2 | **CLEANUP_SUMMARY.md** | 272 | 9.6 KB | High-level overview and decisions |
| 3 | **REPOSITORY_CLEANUP_PLAN.md** | 730 | 24 KB | Detailed execution plan (8 phases) |
| 4 | **CLEANUP_QUICK_REFERENCE.md** | 92 | 2.7 KB | At-a-glance cheat sheet |
| 5 | **CLEANUP_COMMIT_MESSAGE.txt** | 92 | 2.5 KB | Commit message template |
| **TOTAL** | | **1,443** | **45.5 KB** | **Complete planning suite** |

---

## Document Descriptions

### 1. CLEANUP_INDEX.md ⭐ START HERE
**Purpose**: Navigation and overview  
**Audience**: All stakeholders

**Contents**:
- Quick navigation guide ("Want to... → Read this")
- Document descriptions and purposes
- Statistics at-a-glance
- Current vs target state comparison
- Success criteria checklist
- Implementation sequence overview
- Risk management summary

**Use case**: First document to read; explains what each document does and how to use them.

---

### 2. CLEANUP_SUMMARY.md 📊 EXECUTIVE SUMMARY
**Purpose**: High-level understanding  
**Audience**: Project stakeholders, reviewers, decision-makers

**Contents**:
- Current state issues (detailed)
- Before/after structure transformation (visual)
- Critical decisions with rationales:
  - Analysis.m replacement strategy
  - Results/ directory handling
  - Scripts organization approach
  - Test file consolidation
  - Documentation archiving
- Impact summary table
- Risk assessment (LOW/MEDIUM/HIGH)
- Verification strategy
- Implementation order
- Success criteria

**Use case**: Understand the "why" behind the cleanup and the key decisions made.

---

### 3. REPOSITORY_CLEANUP_PLAN.md 📖 IMPLEMENTATION GUIDE
**Purpose**: Step-by-step execution specification  
**Audience**: Implementation agent, technical reviewers

**Contents**:
- Executive summary
- Current state analysis (detailed)
- Target directory structure (complete)
- **8 detailed phases**:
  1. Delete generated/temporary files
  2. Create new directory structure
  3. Reorganize Scripts/ (3A: Drivers, 3B: Solvers)
  4. Move test files to tests/
  5. Archive refactoring documentation
  6. Update .gitignore
  7. Fix import paths in code (15 files)
  8. Handle Results/ directory
- Summary statistics (5 delete, 28 move, etc.)
- Verification checklist
- Risk assessment with mitigations
- Implementation order (recommended sequence)
- Post-cleanup maintenance rules
- Expected benefits
- Open questions/decisions

**Use case**: Follow this phase-by-phase during actual cleanup execution.

---

### 4. CLEANUP_QUICK_REFERENCE.md ⚡ CHEAT SHEET
**Purpose**: Quick lookups during work  
**Audience**: Anyone executing the cleanup

**Contents**:
- At-a-glance statistics table
- Critical changes (Analysis.m, directories, root)
- Execution sequence (10 steps)
- Post-cleanup state (target structure)
- Compact before/after comparison

**Use case**: Keep open in another window during execution for quick reference.

---

### 5. CLEANUP_COMMIT_MESSAGE.txt 📝 COMMIT TEMPLATE
**Purpose**: Pre-written commit message  
**Audience**: Committer (agent or developer)

**Contents**:
- Conventional commit format (feat:)
- Summary section
- Detailed changes (7 categories)
- Files affected (deleted, moved, updated)
- Impact metrics
- Verification checklist
- Breaking changes
- Migration guide

**Use case**: Copy-paste into `git commit` after cleanup execution is complete.

---

## Audit Findings Summary

### Issues Identified

1. **Root Directory Clutter** (21 files → should be 3)
   - 10 refactoring markdown artifacts
   - 6 test files misplaced at root
   - 1 large generated file (chat.json, 8.5 MB)
   - 3 other generated files (logs, diary)

2. **Scripts Organization Problems**
   - Old 6627-line Analysis.m coexists with new 119-line Analysis_New.m
   - No separation: Drivers vs Solvers
   - Methods/ mixes FD-specific and general code

3. **Test Files Disorganized**
   - 6 test files at root instead of tests/

4. **Documentation Scattered**
   - 10 refactoring artifacts at root
   - OWL_Framework_Design.md not in architecture docs

5. **Generated Files Committed**
   - chat.json (8.5 MB)
   - comprehensive_test_log.txt (64 KB)
   - Results/ CSV/MAT files (gitignored but committed)

---

## Proposed Solution Summary

### Action Statistics

| Action | Count | Details |
|--------|-------|---------|
| Files to DELETE | 5 | chat.json, logs, old Analysis.m, etc. |
| Files to MOVE | 28 | Tests, docs, drivers, solvers |
| Directories to CREATE | 7 | Data/, Drivers/, Solvers/, etc. |
| Directories to RENAME | 1 | Visuals → Plotting |
| Directories to DELETE | 2 | Main/, Methods/ (after moves) |
| Files to UPDATE | ~15 | Path corrections |

### Impact Metrics

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Root files | 21 | 3 | **-18 (-86%)** |
| Repo size | X MB | (X-8.6) MB | **-8.6 MB** |
| Main entry point | 6627 lines | 119 lines | **-98%** |
| Test files in tests/ | 2 | 8 | **+6** |
| Scripts/ subdirs | 6 | 7 | **+1** |

---

## Target Directory Structure

```
MECH0020-Numerical-Analysis-of-Tsunami-Vortices-on-Ocean-Surfaces/
├── README.md                      ← Clean, professional root
├── MECH0020_COPILOT_AGENT_SPEC.md
├── .gitignore
│
├── Scripts/
│   ├── Drivers/         ← NEW: Entry points (3 files)
│   ├── Solvers/         ← NEW: Numerical kernels (6 files)
│   │   └── FD/          ← NEW: FD-specific (5 files)
│   ├── Infrastructure/  ← Existing utilities (17 files)
│   ├── Plotting/        ← Renamed from Visuals/ (1 file)
│   ├── UI/              ← Existing UI (2 files)
│   ├── Sustainability/  ← Existing monitoring (5 files)
│   └── Editable/        ← Existing settings (2 files)
│
├── tests/               ← Consolidated (8 files total)
│   ├── Run_All_Tests.m
│   ├── Test_Cases.m
│   └── 6 moved test files
│
├── docs/
│   ├── 01_ARCHITECTURE/ ← OWL_Framework_Design.md moved here
│   ├── 02_DESIGN/
│   ├── 03_NOTEBOOKS/
│   └── markdown_archive/ ← 10 refactoring artifacts archived here
│
├── Data/                ← NEW: Structured data management
│   ├── Input/           ← Reference test cases (versioned)
│   └── Output/          ← Generated results (gitignored)
│
└── utilities/           ← Existing plotting utilities
```

---

## Critical Decisions

### 1. Analysis.m Strategy
**Decision**: Replace old with new  
**Action**: `git mv Scripts/Main/Analysis_New.m Scripts/Drivers/Analysis.m`  
**Rationale**: Analysis_New.m is MECH0020-compliant dispatcher (119 lines vs 6627)

### 2. Results/ Handling
**Decision**: Delete Results/ directory  
**Action**: `git rm -r Results/`  
**Rationale**: Generated outputs, not source; new outputs → Data/Output/

### 3. Scripts Reorganization
**Decision**: Create Drivers/ and Solvers/ subdirectories  
**Rationale**: MECH0020 spec compliance; clear separation of concerns

### 4. Test File Location
**Decision**: Move all 6 root test files to tests/  
**Rationale**: Professional appearance; easier to run all tests

### 5. Documentation Archive
**Decision**: Move (not delete) refactoring artifacts  
**Rationale**: Historical value; don't clutter root; preserve journey

---

## Risk Assessment

### Overall Risk Profile
- **80% Low Risk**: File moves, doc archiving, deletions
- **15% Medium Risk**: Analysis.m replacement, Visuals rename
- **5% High Risk**: Scripts reorganization (paths updates needed)

### Mitigation Strategies
- Use `git mv` to preserve history
- Update paths systematically
- Test after each phase
- Comprehensive verification before commit
- All changes version-controlled (easy rollback)

---

## Implementation Approach

### Recommended Phase Order
1. ✅ Planning (COMPLETE)
2. ⏳ Low-risk operations (delete, create dirs, move tests)
3. ⏳ Medium-risk operations (move drivers, update .gitignore)
4. ⏳ High-risk operations (path updates, solver reorganization)
5. ⏳ Verification (comprehensive testing)

### Estimated Effort
- **Time**: 2-3 hours
- **LOC changes**: 50-100 lines (path updates in ~15 files)
- **Test runs**: After each phase + comprehensive at end

---

## Success Criteria

After execution, the following must be true:

✅ **Structure**
- [ ] Root has only 3 files (README, spec, .gitignore)
- [ ] Scripts/Drivers/ exists with 3 files
- [ ] Scripts/Solvers/ exists with 6 files + FD/ subdirectory
- [ ] Scripts/Main/ and Scripts/Methods/ do not exist
- [ ] tests/ contains 8 test files

✅ **Functionality**
- [ ] All tests pass: `tests/Run_All_Tests.m`
- [ ] UI launches: `Scripts/Drivers/Analysis.m`
- [ ] Convergence agent runs: `Scripts/Drivers/run_adaptive_convergence.m`
- [ ] No path errors in MATLAB

✅ **Quality**
- [ ] Repository size reduced by ~8.6 MB
- [ ] Analysis.m is 119-line dispatcher (not 6627-line monolith)
- [ ] Documentation discoverable in docs/
- [ ] Historical artifacts preserved in markdown_archive/

---

## Next Steps

1. **Review** these planning documents
2. **Approve** the cleanup plan
3. **Execute** Phases 1-10 from REPOSITORY_CLEANUP_PLAN.md
4. **Verify** success criteria checklist
5. **Commit** using CLEANUP_COMMIT_MESSAGE.txt
6. **Create PR** to merge into main branch

---

## Document Usage Guide

**For Quick Understanding**:
1. Read CLEANUP_INDEX.md (5 min)
2. Read CLEANUP_SUMMARY.md (10 min)

**For Execution**:
1. Follow REPOSITORY_CLEANUP_PLAN.md phase-by-phase
2. Keep CLEANUP_QUICK_REFERENCE.md open for lookups
3. Use CLEANUP_COMMIT_MESSAGE.txt when committing

**For Review**:
1. CLEANUP_SUMMARY.md for decisions and rationale
2. REPOSITORY_CLEANUP_PLAN.md for implementation details
3. Success criteria checklist for verification

---

**Status**: ✅ PLANNING COMPLETE  
**Ready for**: Execution approval  
**Estimated implementation**: 2-3 hours  
**Estimated impact**: Major improvement in repository organization
