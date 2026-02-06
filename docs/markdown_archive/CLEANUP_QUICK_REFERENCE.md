# Repository Cleanup - Quick Reference

**Full Plan**: See `REPOSITORY_CLEANUP_PLAN.md` (730 lines)  
**Status**: Ready for execution  
**Branch**: `copilot/clean-up-repo-file-system`

---

## At a Glance

| Category | Count | Action |
|----------|-------|--------|
| Files to DELETE | 5 | Remove generated/duplicate files |
| Files to MOVE | 28 | Reorganize into proper directories |
| Directories to CREATE | 7 | New Data/ and Scripts/ structure |
| Directories to RENAME | 1 | Visuals → Plotting |
| Directories to DELETE | 2 | Empty after moves (Main, Methods) |
| Files to UPDATE | ~15 | Path corrections |

**Repo size reduction**: ~8.6 MB (removing chat.json)

---

## Critical Changes

### 1. Analysis.m Replacement ⚠️
```
BEFORE: Scripts/Main/Analysis.m (6627 lines, monolithic)
AFTER:  Scripts/Drivers/Analysis.m (119 lines, thin dispatcher)

ACTION: git mv Scripts/Main/Analysis_New.m Scripts/Drivers/Analysis.m
        rm Scripts/Main/Analysis.m
```

### 2. Directory Reorganization 📁
```
Scripts/Main/     → Scripts/Drivers/
Scripts/Methods/  → Scripts/Solvers/ (and Scripts/Solvers/FD/)
Scripts/Visuals/  → Scripts/Plotting/
```

### 3. Root Cleanup 🧹
```
BEFORE: 21 files in root (14 markdown docs, 6 test files, 1 .gitignore)
AFTER:  3 files in root (README.md, MECH0020_COPILOT_AGENT_SPEC.md, .gitignore)
```

---

## Execution Sequence

1. ✅ Create plan and get approval
2. ⏳ Delete generated files (chat.json, logs, etc.)
3. ⏳ Create new directory structure
4. ⏳ Move test files to tests/
5. ⏳ Archive refactoring docs to docs/markdown_archive/
6. ⏳ Reorganize Scripts/ (Drivers, Solvers)
7. ⏳ Update .gitignore
8. ⏳ Fix import paths in ~15 files
9. ⏳ Run comprehensive verification
10. ⏳ Commit and push

**Estimated time**: 2-3 hours

---

## Post-Cleanup State

### Root Directory (Target)
```
MECH0020-Numerical-Analysis-of-Tsunami-Vortices-on-Ocean-Surfaces/
├── README.md                      ← User-facing documentation
├── MECH0020_COPILOT_AGENT_SPEC.md ← Agent specification
├── .gitignore                     ← Git configuration
├── Scripts/                       ← All MATLAB code
├── tests/                         ← All test files
├── utilities/                     ← Plotting utilities
├── Data/                          ← Input data & outputs
├── docs/                          ← Documentation & history
└── .github/                       ← GitHub configuration
```

### Clean Root
```
BEFORE: 21 files in root
AFTER:  3 files in root
Reduction: 18 files moved or deleted
```

---

**Full Details**: See `REPOSITORY_CLEANUP_PLAN.md`
