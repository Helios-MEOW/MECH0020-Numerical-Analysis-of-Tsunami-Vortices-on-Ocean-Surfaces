# Error Registry

This document records all errors encountered and resolved during development and maintenance.

## Schema

| Field | Description |
|-------|-------------|
| Error ID | Unique sequential identifier (ERR-XXXX) |
| Date | Date error was identified (YYYY-MM-DD) |
| Identifier | MATLAB error identifier or code |
| Message | Error message text |
| Location | File:Line where error occurred |
| Stack Excerpt | Relevant portion of stack trace |
| Reproduction | Command or steps to reproduce |
| Root Cause | Brief analysis of why error occurred |
| Fix Summary | Description of the fix applied |
| Commit Hash | Git commit that resolved the error |
| Status | RESOLVED / OPEN / WONTFIX |

## Entry Template

```
### ERR-XXXX: Brief Description

- **Date:** YYYY-MM-DD
- **Identifier:** `MATLAB:identifier:here`
- **Message:** Error message text
- **Location:** `filename.m:123`
- **Stack Excerpt:**
  ```
  Error in function_name (line 123)
      offending_line_of_code
  ```
- **Reproduction:** `Run_All_Tests` or specific command
- **Root Cause:** Explanation of why this happened
- **Fix Summary:** What was changed to fix it
- **Commit Hash:** `abc1234`
- **Status:** RESOLVED
```

---

## Resolved Errors

### ERR-0001: Undeclared property dev_original_callbacks in UIController

- **Date:** 2026-02-09
- **Identifier:** `MATLAB:noSuchMethodOrField`
- **Message:** Property 'dev_original_callbacks' not found or not accessible
- **Location:** `UIController.m:1886`
- **Stack Excerpt:**
  ```
  Error in UIController/enable_click_inspector (line 1886)
      app.dev_original_callbacks = containers.Map(...);
  ```
- **Reproduction:** Enable Developer Mode in UI
- **Root Cause:** Property `dev_original_callbacks` used in methods but not declared in `properties` block
- **Fix Summary:** Added `dev_original_callbacks` to `properties (Access = public)` block and initialized to `[]` in constructor
- **Commit Hash:** `a0fac27`
- **Status:** RESOLVED

### ERR-0002: isfield used on class object instead of isprop

- **Date:** 2026-02-09
- **Identifier:** `MATLAB:isfield:InvalidType`
- **Message:** isfield() expects a struct, not a class object
- **Location:** `UIController.m:1892`
- **Stack Excerpt:**
  ```
  Error in UIController/disable_click_inspector (line 1892)
      if ~isfield(app, 'dev_original_callbacks') ...
  ```
- **Reproduction:** Toggle Developer Mode off after enabling
- **Root Cause:** `isfield()` does not work on class objects; should use `isempty()` or `isa()` for type checking
- **Fix Summary:** Changed condition to check `isempty(app.dev_original_callbacks)` and `isa(..., 'containers.Map')`
- **Commit Hash:** `a0fac27`
- **Status:** RESOLVED

### ERR-0003: exit() calls terminate MATLAB in CI/testing

- **Date:** 2026-02-09
- **Identifier:** N/A (design issue, not runtime error)
- **Message:** MATLAB terminates unexpectedly during test runs
- **Location:** Multiple files: `Run_All_Tests.m`, `static_analysis.m`, `test_architecture_compliance.m`, `Run_All_Tests_Legacy.m`
- **Stack Excerpt:** N/A
- **Reproduction:** Run tests in CI or batch mode
- **Root Cause:** `exit()` function terminates MATLAB process, preventing subsequent test phases or scripts from running
- **Fix Summary:** Removed all `exit()` calls; replaced with return codes, warnings, and `rethrow(ME)` for proper error propagation
- **Commit Hash:** `7a4afd8`
- **Status:** RESOLVED

### ERR-0004: RunIDGenerator string concatenation with char type

- **Date:** 2026-02-09
- **Identifier:** `MATLAB:sizeDimensionsMustMatch`
- **Message:** Arrays have incompatible sizes for this operation
- **Location:** `RunIDGenerator.m:147`
- **Stack Excerpt:**
  ```
  Error in RunIDGenerator.struct_to_string (line 147)
      str = str + sprintf('%s=%g;', fields{i}, val);
  ```
- **Reproduction:** Run `ModeDispatcher` with any configuration
- **Root Cause:** Variable `str` initialized with single quotes (`str = ''`) creates a char array. The `+` operator for string concatenation requires MATLAB string type (double quotes). Char + string causes dimension mismatch.
- **Fix Summary:** Changed `str = ''` to `str = ""` (string literal) and added `isscalar(val)` check with array handling for non-scalar numeric values
- **Commit Hash:** `74d9ec6`
- **Status:** RESOLVED

### ERR-0005: IC type normalization missing hyphen conversion

- **Date:** 2026-02-09
- **Identifier:** (thrown error)
- **Message:** Unknown ic_type: lamb-oseen
- **Location:** `initialise_omega.m:167`
- **Stack Excerpt:**
  ```
  Error in initialise_omega (line 167)
      error('Unknown ic_type: %s', ic_type);
  ```
- **Reproduction:** Run Evolution mode with `ic_type = 'Lamb-Oseen'`
- **Root Cause:** IC type normalization lowercased `Lamb-Oseen` to `lamb-oseen` but switch cases use underscore format `lamb_oseen`. Hyphen was not converted to underscore.
- **Fix Summary:** Added `strrep(ic_type, '-', '_')` and `strrep(ic_type, ' ', '_')` after lowercasing in the normalizer block
- **Commit Hash:** `74d9ec6`
- **Status:** RESOLVED

### ERR-0006: Run_All_Tests references non-existent path

- **Date:** 2026-02-09
- **Identifier:** (MATLAB warning)
- **Message:** Name is nonexistent or not a directory: Scripts\Solvers\FD
- **Location:** `Run_All_Tests.m:422` (add_all_paths function)
- **Stack Excerpt:**
  ```
  Warning in addpath (line 96)
  In Run_All_Tests>add_all_paths (line 422)
  ```
- **Reproduction:** Run `Run_All_Tests` from tests directory
- **Root Cause:** Path setup function included `Scripts/Solvers/FD` which was removed during restructuring. Missing paths for Spectral and FiniteVolume methods.
- **Fix Summary:** Removed non-existent `Scripts/Solvers/FD` path; added correct paths: `Scripts/Methods/FiniteVolume` and `Scripts/Methods/Spectral`
- **Commit Hash:** `74d9ec6`
- **Status:** RESOLVED

### ERR-0007: Function/variable name collision causes infinite recursion

- **Date:** 2026-02-09
- **Identifier:** `MATLAB:recursionLimit`
- **Message:** Maximum recursion limit reached (MATLAB crash with exit code 1)
- **Location:** `Parameters.m:1` and `Settings.m:1`
- **Stack Excerpt:**
  ```
  (MATLAB exits with code 1 before producing stack trace)
  Symptoms: Test 2 (Convergence) crashes after Mesh 1 completes
  ```
- **Reproduction:** Run `Parameters()` or `Settings()` function, or run any test that calls them
- **Root Cause:** Functions `Parameters.m` and `Settings.m` used the same name for output variable as the function name. In MATLAB, when a function body references `Parameters.x = value`, it attempts to call `Parameters()` recursively instead of creating a struct field, causing infinite recursion and immediate MATLAB termination.
- **Fix Summary:** Renamed internal output variables: `Parameters` → `params` in Parameters.m, `Settings` → `s` in Settings.m. This breaks the name collision while preserving the external API.
- **Commit Hash:** `5ee6ae5`
- **Status:** RESOLVED

---

## Open Issues

(Entries for known issues not yet resolved)

---

## Notes

- All errors encountered during the stabilization PR are logged here
- This file is permanent and should be maintained for future reference
- Use `ErrorHandler.log()` to automatically append entries when feasible

---
Last Updated: 2026-02-09
