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
