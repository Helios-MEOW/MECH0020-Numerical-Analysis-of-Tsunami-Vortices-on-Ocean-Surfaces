# Static Analyzer Guide (v2.0)

## Overview

The MECH0020 Static Analysis System is a crash-hardened, single-file MATLAB script that performs comprehensive code quality checks across the repository. It replaces the previous version with improved reliability, structured reporting, and deterministic exit codes.

## Key Features

### 1. Crash-Safe Architecture
- **Per-file processing**: Analyzes files one at a time to avoid memory issues
- **Exception handling**: Catches and reports errors without crashing
- **Phase tracking**: Reports which phase completed/failed
- **Graceful degradation**: Continues analysis even if individual files fail

### 2. Structured Issue Codes

All issues are tagged with structured codes for systematic tracking:

| Code Pattern | Category | Example |
|--------------|----------|---------|
| `MLAB-CRIT-xxx` | Critical MATLAB Code Analyzer issues | `MLAB-CRIT-NODEF` |
| `MLAB-MAJR-xxx` | Major MATLAB Code Analyzer issues | `MLAB-MAJR-AGROW` |
| `MLAB-MINR-xxx` | Minor MATLAB Code Analyzer issues | `MLAB-MINR-xxx` |
| `REPO-xxx` | Repository structure issues | `REPO-001` (missing dir) |
| `CUST-xxx` | Custom pattern checks | `CUST-001` (Position usage) |
| `ANLZ-xxx` | Analyzer internal errors | `ANLZ-001` (checkcode fail) |

### 3. Comprehensive Reporting

Generates two complementary reports:

#### JSON Report (`static_analysis_report.json`)
- Machine-readable format for CI/CD integration
- Complete metadata (timestamp, MATLAB version, hostname)
- All issues with full details
- Phase execution timings
- Structured for automated processing

#### Markdown Report (`static_analysis_report.md`)
- Human-readable summary
- Organized by severity (CRITICAL, MAJOR, MINOR)
- Each issue includes:
  - File path and line number
  - Description
  - Actionable remediation hints
- Phase execution summary

### 4. Deterministic Exit Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| 0 | PASS | No issues found; CI should succeed |
| 1 | FAIL | Issues found; see reports for details |
| 2 | ERROR | Analyzer crashed; check logs for exception |

## Usage

### Basic Usage

```matlab
cd tests
static_analysis
```

### CI/CD Usage (Headless)

```bash
matlab -batch "cd tests; static_analysis"
echo $?  # Check exit code
```

### GitHub Actions Usage

```yaml
- name: Run static analysis
  uses: matlab-actions/run-command@v2
  with:
    command: |
      cd tests
      static_analysis
```

## Analysis Phases

The analyzer executes in 5 phases:

### Phase 1: File Collection
- Scans `Scripts/`, `utilities/`, `tests/` for `.m` files
- Pre-allocates arrays to avoid memory growth
- Sorts files for deterministic order

### Phase 2: MATLAB Code Analyzer
- Runs `checkcode` per-file with exception handling
- Maps MATLAB issues to structured codes
- Classifies severity (CRITICAL/MAJOR/MINOR)
- Reports progress every 10 files

### Phase 3: Custom Checks
- **Check 1**: Required directories exist
- **Check 2**: Entry point files exist
- **Check 3**: UIController Position usage patterns

### Phase 4: Aggregation
- Counts issues by severity
- Organizes issues by file and category
- Prepares summary statistics

### Phase 5: Reporting
- Writes JSON report (incremental)
- Writes Markdown report (formatted)
- Displays console summary

## Issue Code Reference

### MATLAB Code Analyzer Issues

#### CRITICAL Issues

| Code | MATLAB ID | Description | Remediation |
|------|-----------|-------------|-------------|
| `MLAB-CRIT-NODEF` | NODEF | Function called but not defined | Add function definition or check spelling |
| `MLAB-CRIT-NOSEM` | NOSEM | Missing semicolon | Add semicolon to suppress output |
| `MLAB-CRIT-INUSD` | INUSD | Variable set but never used | Remove or use the variable |
| `MLAB-CRIT-MCNPR` | MCNPR | Filename/function name mismatch | Rename file or function |
| `MLAB-CRIT-MCVID` | MCVID | Invalid identifier | Use valid MATLAB names |

#### MAJOR Issues

| Code | MATLAB ID | Description | Remediation |
|------|-----------|-------------|-------------|
| `MLAB-MAJR-NBRAK` | NBRAK | Unbalanced brackets | Fix syntax |
| `MLAB-MAJR-NOPRT` | NOPRT | Function has no output | Return a value or convert to script |
| `MLAB-MAJR-AGROW` | AGROW | Variable growing in loop | Pre-allocate array |
| `MLAB-MAJR-SAGROW` | SAGROW | String growing in loop | Pre-allocate string array |
| `MLAB-MAJR-PSIZE` | PSIZE | Variable size changes | Pre-allocate for performance |
| `MLAB-MAJR-GVMIS` | GVMIS | Global variable mismatch | Declare global consistently |

### Repository Issues

| Code | Description | Remediation |
|------|-------------|-------------|
| `REPO-001` | Missing required directory | Create directory structure |
| `REPO-002` | Missing entry point file | Ensure file exists |

### Custom Checks

| Code | Description | Remediation |
|------|-------------|-------------|
| `CUST-001` | Problematic Position usage in UIController | Use `Units='normalized'` instead |

### Analyzer Errors

| Code | Description | Remediation |
|------|-------------|-------------|
| `ANLZ-001` | checkcode failed for file | File may have syntax errors |
| `ANLZ-002` | Failed to read/check file | File may be corrupted |

## Crash Prevention Mechanisms

### 1. Memory Management
- Pre-allocated arrays instead of growing arrays in loops

- Per-file processing instead of batch processing

### 2. Exception Handling
- Top-level try-catch for catastrophic failures
- Per-phase try-catch for phase-specific errors
- Per-file try-catch in checkcode loop
- Graceful degradation (partial reports on error)

### 3. Progress Tracking
- Phase boundaries clearly marked
- Console progress updates (every 10 files)
- Elapsed time tracking per phase
- Last completed phase reported on crash

## Extending the Analyzer

### Adding a New Custom Check

1. Add check logic in `run_custom_checks_safe()` function
2. Define a new issue code (e.g., `CUST-002`)
3. Set appropriate severity (CRITICAL/MAJOR/MINOR)
4. Provide actionable remediation hint

Example:

```matlab
% Check 4: Example new check
fprintf('  [4/4] Checking for deprecated functions...\n');
deprecated_funcs = {'oldFunction1', 'oldFunction2'};

for i = 1:length(file_list)
    file_content = fileread(file_list{i});
    for j = 1:length(deprecated_funcs)
        if contains(file_content, deprecated_funcs{j})
            issue_id = issue_id + 1;
            issue_struct = struct(...
                'id', issue_id, ...
                'code', 'CUST-002', ...
                'severity', 'MAJOR', ...
                'category', 'DEPRECATED', ...
                'file', file_list{i}, ...
                'line', 0, ...
                'message', sprintf('Uses deprecated function: %s', deprecated_funcs{j}), ...
                'remediation', 'Replace with modern equivalent');
            issues = [issues, issue_struct];
        end
    end
end
```

### Creating an Allowlist

To exclude known issues:

1. Modify the check logic to skip allowlisted cases
2. Document the allowlist pattern

Example (already implemented for Position check):

```matlab
% Allowlist patterns
allowed_patterns = {'dialog_fig', 'inspector_fig', 'rectangle'};

% Check if issue is allowlisted
is_allowed = false;
for j = 1:length(allowed_patterns)
    if contains(line, allowed_patterns{j})
        is_allowed = true;
        break;
    end
end

if ~is_allowed
    % Report issue
end
```

## Troubleshooting

### Analyzer Crashes with Exit Code 2

Check the console output for:
1. Exception message
2. Last completed phase
3. Stack trace

The partial JSON report may contain additional details.

### High Memory Usage

- Reduce batch size in checkcode loop (already per-file)
- Check for large files being processed
- Review custom checks for memory leaks

### Slow Execution

- Check phase timings in report
- Identify slow custom checks
- Consider parallelization (future enhancement)

## Version History

### v2.0 (Current)
- Complete rewrite for crash safety
- Structured issue code taxonomy
- JSON + Markdown reporting
- Deterministic exit codes
- Per-file processing
- Phase tracking
- Exception handling throughout

### v1.0 (Legacy)
- Basic checkcode integration
- Console-only output
- Growing arrays (memory issues)
- Limited error handling

## Future Enhancements

Potential improvements (not yet implemented):

1. **Parallel processing**: Process files in parallel for speed
2. **Incremental analysis**: Only analyze changed files
3. **HTML reports**: Interactive web-based reports
4. **Trend tracking**: Track issues over time
5. **Auto-fix**: Suggest or apply automated fixes
6. **Integration**: Push results to external issue trackers

---

*This guide is maintained as part of the MECH0020 repository.*
*Last updated: 2026-02-08*
