# Static Analysis Issue Taxonomy

This document defines every issue type detected by the MECH0020 static analyser,
explains what each issue means in the context of this codebase, and provides
the canonical fix strategy.

## Severity Levels

| Level | Meaning | Gate Behaviour |
|-------|---------|----------------|
| **CRITICAL** | Will cause a runtime error or crash. Code cannot execute. | Blocks CI. Must fix before merging. |
| **MAJOR** | Logic risk (wrong results) or measurable performance degradation in hot paths. | Warned in CI. Should fix before merging. |
| **MINOR** | Style, readability, or best-practice deviation. No runtime impact. | Informational only. Fix when convenient. |

## Impact Categories

| Impact | Description |
|--------|-------------|
| `RUNTIME_ERROR_LIKELY` | Code will throw an error at runtime. |
| `LOGIC_RISK` | Code may produce incorrect numerical results. |
| `PERFORMANCE_STYLE` | Code is correct but slow or hard to read. |
| `UNKNOWN` | Unclassified minor issue. |

---

## CRITICAL Issues (Runtime Error Likely)

### MLAB-CRIT-NODEF — Undefined Function or Variable
- **checkcode ID**: `NODEF`
- **What it means**: A function or variable is referenced but never defined in the current scope. MATLAB will throw `Undefined function or variable 'X'` at runtime.
- **Fix strategy**: Either (a) add the missing function/file to the path, (b) correct the spelling, or (c) define the variable before use.
- **Example**: Calling `Spectral_Analysis(...)` when no `Spectral_Analysis.m` exists.

### MLAB-CRIT-NBRAK — Unbalanced Brackets
- **checkcode ID**: `NBRAK`
- **What it means**: Mismatched parentheses, brackets, or braces. MATLAB cannot parse the file.
- **Fix strategy**: Locate the bracket mismatch (MATLAB highlights it) and correct it.

### MLAB-CRIT-MCNPR — File Name / Function Name Mismatch
- **checkcode ID**: `MCNPR`
- **What it means**: The file is named `X.m` but the function inside is `function Y(...)`. MATLAB will ignore the function name and use the file name, causing confusion.
- **Fix strategy**: Rename either the file or the function so they match.

### MLAB-CRIT-MCVID — Invalid Identifier
- **checkcode ID**: `MCVID`
- **What it means**: A variable or function name uses invalid characters (spaces, leading digits, etc.).
- **Fix strategy**: Rename the identifier to use only letters, digits, and underscores, starting with a letter.

---

## MAJOR Issues — Logic Risk

### MLAB-MAJR-INUSD — Input Argument Not Used
- **checkcode ID**: `INUSD`
- **What it means**: A function declares an input argument but never reads it. This usually means the interface is wider than needed, or a planned feature was never implemented.
- **Fix strategy**: 
  - If the argument is truly unused: replace it with `~` in the signature (e.g., `function f(x, ~, z)`).
  - If the argument should be used: add the missing logic.
  - If the argument is kept for interface consistency (e.g., callback signature): add `%#ok<INUSD>` suppression.
- **This codebase**: `fd_diagnostics.m` had `cfg` and `ctx` unused; `mode_convergence.m` and `mode_parameter_sweep.m` had `Settings` unused in local simulation runners.

### MLAB-MAJR-GVMIS — Global Variable Mismatch
- **checkcode ID**: `GVMIS`
- **What it means**: A `global` variable is declared in one place but not consistently in all functions that use it.
- **Fix strategy**: Ensure every function that reads/writes the global declares it with the same name. Better yet, refactor to remove globals entirely.

### MLAB-MAJR-NOPRT — Function Has No Output
- **checkcode ID**: `NOPRT`
- **What it means**: A function declares output arguments in its signature but some code paths never assign them.
- **Fix strategy**: Ensure all declared outputs are assigned on every code path, or remove unused outputs from the signature.

---

## MAJOR Issues — Performance / Style

### MLAB-MAJR-AGROW — Variable Growing Inside Loop
- **checkcode ID**: `AGROW`
- **What it means**: An array or cell array is extended (e.g., `x(end+1) = ...` or `x = [x; new]`) inside a loop. MATLAB must copy the entire array on every iteration, giving $O(n^2)$ memory operations for $n$ iterations.
- **Fix strategy**:
  1. **Hot loops** (time-stepping, data collection): Pre-allocate to known size, use an index counter, truncate at end.
     ```matlab
     result = zeros(1, N);  % Pre-allocate
     for i = 1:N
         result(i) = compute(i);
     end
     ```
  2. **Bounded appends** (≤50 iterations, UI logs, validation): Suppress with `%#ok<AGROW>`.
  3. **Sequential if-checks** (validation error collection): Not actually in a loop — suppress with `%#ok<AGROW>`.
- **This codebase**: Fixed in `disperse_vortices.m`, `initialize_directory_structure.m`, `ErrorHandler.m`, `ErrorRegistry.m`. Suppressed in validation functions, UI logs, and analysis tools.

### MLAB-MAJR-SAGROW — String Growing Inside Loop
- **checkcode ID**: `SAGROW`
- **What it means**: Same as AGROW but for string arrays.
- **Fix strategy**: Same as AGROW — pre-allocate or suppress.

### MLAB-MAJR-PSIZE — Variable Size Changes
- **checkcode ID**: `PSIZE`
- **What it means**: A variable changes size (dimensions) unexpectedly, often due to conditional assignment of different-sized results.
- **Fix strategy**: Ensure the variable always has the same shape, or use separate variables.

### MLAB-MAJR-NOSEM — Missing Semicolon
- **checkcode ID**: `NOSEM`
- **What it means**: A statement lacks a trailing semicolon, so its result will be printed to the Command Window. In batch/CI runs this creates massive, slow output.
- **Fix strategy**: Add `;` at the end of the statement unless the output is intentionally displayed.

---

## MINOR Issues (Style / Best Practices)

### MLAB-MINR-NASGU — Variable Assigned But Not Used
- **checkcode ID**: `NASGU`
- **What it means**: A variable is assigned a value but never read afterward. Dead code.
- **Fix strategy**: Remove the assignment, or replace with `~` if it's a function output you don't need.

### MLAB-MINR-AND — Use `&&` Instead of `&`
- **checkcode ID**: `AND`
- **What it means**: Using `&` (element-wise AND) where `&&` (short-circuit AND) is intended for scalar logic.
- **Fix strategy**: Replace `&` with `&&` in scalar conditional expressions.

### MLAB-MINR-OR — Use `||` Instead of `|`
- **checkcode ID**: `OR`
- **What it means**: Same as above but for OR operator.
- **Fix strategy**: Replace `|` with `||` in scalar conditional expressions.

### MLAB-MINR-ISMT — Empty Block
- **checkcode ID**: `ISMT`
- **What it means**: An `if`/`for`/`while` block has no statements inside.
- **Fix strategy**: Either add the intended logic or remove the empty block.

### Other MINOR codes
Any checkcode ID not listed above is classified as MINOR by default. These are typically style suggestions from MATLAB's M-Lint. Review them and fix if they improve readability.

---

## Repository-Specific Issues

### REPO-001 — Missing Required Directory
- **Severity**: CRITICAL
- **What it means**: A directory required by the project structure is missing. Functions that try to write results will fail.
- **Fix strategy**: Create the missing directory (the framework does this automatically via `initialize_directory_structure.m`).

### REPO-002 — Missing Entry Point
- **Severity**: CRITICAL
- **What it means**: A required entry-point file (e.g., `Analysis.m`, `UIController.m`) is missing.
- **Fix strategy**: Restore the file from version control or recreate it.

### CUST-001 — Absolute Position Usage in UIController
- **Severity**: MINOR
- **What it means**: Using `Position` with absolute pixel coordinates in the UI. This breaks cross-platform compatibility (different DPI, screen sizes).
- **Fix strategy**: Use `Units = 'normalized'` or grid-based layout instead.

---

## Current Status (Post-Fixes)

All CRITICAL issues: **0 remaining**  
All MAJOR issues: **Fixed or suppressed** — no unsuppressed AGROW/INUSD/NASGU remain in production code.  
MINOR issues: Reviewed and left as informational.

## Running the Analyser

```matlab
cd tests
static_analysis()                       % Report mode (never fails)
static_analysis('FailOnIssues', true)   % Gate mode (fails on CRITICAL)
static_analysis('Verbose', true)        % Detailed per-file output
```

Reports are written to:
- `tests/static_analysis_report.json` (machine-readable)
- `tests/static_analysis_report.md` (human-readable)
