# Verification Guide for File Organization PR

This guide provides step-by-step instructions to verify that the file reorganization was successful and the repository remains fully functional.

## Quick Verification Checklist

Use this checklist to quickly verify the PR:

- [ ] All files in expected locations
- [ ] No broken path references
- [ ] Configuration files load correctly
- [ ] Standard mode runs
- [ ] UI mode opens
- [ ] Tests pass
- [ ] Documentation is accurate

## Detailed Verification Steps

### 1. Directory Structure Verification

**Check that all new directories exist:**
```bash
ls -la Scripts/
# Expected directories:
# - Config/
# - Drivers/
# - Grid/
# - IO/
# - Methods/FiniteDifference/
# - Metrics/
# - Plotting/
# - Solvers/
# - Sustainability/
# - UI/
# - Utils/
```

**Check that old directories are gone:**
```bash
# These should NOT exist:
ls Scripts/Editable/        # Should fail
ls Scripts/Infrastructure/  # Should fail
ls Scripts/Solvers/FD/      # Should fail
ls docs/                    # Should fail
ls utilities/               # Should fail (or only contain non-MATLAB files)
```

**Verify file counts:**
```bash
find Scripts -name "*.m" -type f | wc -l
# Expected: ~51 MATLAB files
```

### 2. Configuration System Verification

**Test unified configuration loading:**
```matlab
% Start MATLAB in repository root
cd Scripts/Config

% Test new unified config
params = default_parameters('FD');
assert(isfield(params, 'Nx'), 'Missing Nx field');
assert(params.Nx == 128, 'Incorrect default Nx');
fprintf('✓ default_parameters.m works\n');

settings = user_settings('Standard');
assert(isfield(settings, 'save_figures'), 'Missing save_figures field');
fprintf('✓ user_settings.m works\n');

% Test method-specific defaults
params_spectral = default_parameters('Spectral');
assert(strcmp(params_spectral.analysis_method, 'Spectral'), 'Wrong method name');
fprintf('✓ Method-specific defaults work\n');

% Test mode-specific settings
settings_ui = user_settings('UI');
assert(settings_ui.monitor_enabled == true, 'UI monitor should be enabled');
fprintf('✓ Mode-specific settings work\n');
```

**Test legacy configuration (backward compatibility):**
```matlab
cd Scripts/Config

% Test legacy config files
Parameters = Default_FD_Parameters();
assert(isfield(Parameters, 'Nx'), 'Legacy config missing Nx');
fprintf('✓ Default_FD_Parameters.m still works\n');

Settings = Default_Settings();
assert(isfield(Settings, 'save_figures'), 'Legacy settings missing save_figures');
fprintf('✓ Default_Settings.m still works\n');
```

### 3. Path Resolution Verification

**Test that all paths resolve correctly:**
```matlab
% Start MATLAB in repository root
cd Scripts/Drivers

% Run Analysis.m path setup (without executing full script)
script_dir = fileparts(mfilename('fullpath'));
repo_root = fullfile(script_dir, '..', '..');

% Add paths as Analysis.m does
addpath(fullfile(repo_root, 'Scripts', 'Drivers'));
addpath(fullfile(repo_root, 'Scripts', 'Solvers'));
addpath(fullfile(repo_root, 'Scripts', 'Methods', 'FiniteDifference'));
addpath(fullfile(repo_root, 'Scripts', 'Config'));
addpath(fullfile(repo_root, 'Scripts', 'IO'));
addpath(fullfile(repo_root, 'Scripts', 'Grid'));
addpath(fullfile(repo_root, 'Scripts', 'Metrics'));
addpath(fullfile(repo_root, 'Scripts', 'UI'));
addpath(fullfile(repo_root, 'Scripts', 'Plotting'));
addpath(fullfile(repo_root, 'Scripts', 'Sustainability'));
addpath(fullfile(repo_root, 'Scripts', 'Utils'));

% Verify key functions exist
assert(exist('default_parameters', 'file') == 2, 'default_parameters not found');
assert(exist('ic_factory', 'file') == 2, 'ic_factory not found');
assert(exist('PathBuilder', 'file') == 2, 'PathBuilder not found');
assert(exist('MetricsExtractor', 'file') == 2, 'MetricsExtractor not found');
assert(exist('Plot_Format', 'file') == 2, 'Plot_Format not found');
fprintf('✓ All key functions found on path\n');
```

### 4. Standard Mode Verification

**Run Standard Mode simulation:**
```matlab
cd Scripts/Drivers
% Open Analysis.m and check the startup sequence
% Or run a minimal simulation:

% Build configuration
addpath(fullfile('..', 'Config'));
addpath(fullfile('..', 'IO'));
Run_Config = Build_Run_Config('FD', 'Evolution', 'Lamb-Oseen');
Parameters = default_parameters('FD');
Settings = user_settings('Standard');

% Override for quick test
Parameters.Nx = 32;
Parameters.Ny = 32;
Parameters.Tfinal = 0.1;

fprintf('✓ Standard mode configuration built successfully\n');
% Full execution test would call ModeDispatcher
```

### 5. UI Mode Verification

**Test UI startup (if MATLAB desktop available):**
```matlab
cd Scripts/Drivers
% This should open the startup dialog
Analysis

% Expected behavior:
% 1. Startup dialog appears
% 2. Can select "UI Mode" or "Standard Mode"
% 3. If UI Mode selected, 3-tab interface opens
% 4. All tabs functional (Config, Monitor, Results)
```

**Check UI path setup:**
```matlab
% Verify UIController can find required paths
ui_dir = fileparts(which('UIController'));
scripts_dir = fileparts(ui_dir);

% These paths should exist
assert(exist(fullfile(scripts_dir, 'Config'), 'dir') == 7, 'Config dir not found');
assert(exist(fullfile(scripts_dir, 'IO'), 'dir') == 7, 'IO dir not found');
assert(exist(fullfile(scripts_dir, 'Grid'), 'dir') == 7, 'Grid dir not found');
fprintf('✓ UI path setup correct\n');
```

### 6. Convergence Agent Verification

**Test convergence agent:**
```matlab
cd Scripts/Drivers
% Check that convergence driver can load
addpath(fullfile('..', 'Config'));
assert(exist('AdaptiveConvergenceAgent', 'file') == 2, 'Agent not found');
fprintf('✓ Convergence agent accessible\n');

% Full test would run:
% run_adaptive_convergence
% But this may take time, so manual testing is recommended
```

### 7. File Move Verification

**Verify git history preserved:**
```bash
# Check that git mv preserved history for key files
git log --follow -- Scripts/Config/Default_FD_Parameters.m
# Should show history from when it was in Scripts/Editable/

git log --follow -- Scripts/Methods/FiniteDifference/Finite_Difference_Analysis.m
# Should show history from when it was in Scripts/Solvers/FD/

git log --follow -- Scripts/IO/PathBuilder.m
# Should show history from when it was in Scripts/Infrastructure/
```

**Verify no duplicate files:**
```bash
# Make sure old locations are truly empty
find . -name "Default_FD_Parameters.m"
# Should only show Scripts/Config/Default_FD_Parameters.m

find . -name "ic_factory.m"
# Should only show Scripts/Grid/ic_factory.m
```

### 8. Documentation Verification

**Check README accuracy:**
```bash
# Verify README references correct paths
grep "Scripts/Config" README.md
grep "Scripts/Methods/FiniteDifference" README.md
grep "Docs/Extra" README.md

# Make sure old paths are not mentioned
grep "Scripts/Editable" README.md  # Should fail or only in legacy section
grep "Scripts/Infrastructure" README.md  # Should fail or only in comparison
```

**Check config documentation:**
```bash
# Verify config README exists and is comprehensive
cat Scripts/Config/README.md
# Should contain usage examples, migration guide, etc.
```

**Check move table:**
```bash
# Verify move table is complete
cat FILE_MOVES.md
# Should list all 76 moved files
```

### 9. Test Suite Verification

**Run existing tests:**
```matlab
cd tests
% If Run_All_Tests.m exists:
Run_All_Tests

% Or run individual tests:
test_method_dispatcher
test_ui_startup
test_refactoring

% Expected: All tests should pass
% Note: Some tests may fail if they're testing deprecated functionality
```

### 10. Clean Repository Check

**Verify no extra files:**
```bash
git status
# Should show: "nothing to commit, working tree clean"

# Check for any untracked files that should be ignored
git status --ignored
# Verify .gitignore is working correctly
```

**Verify .gitignore updated:**
```bash
cat .gitignore | grep "utilities/release"
# Should show: utilities/release/
```

## Expected Test Results

### All Verification Passed ✓
If all checks pass, you should see:
- ✓ All files in expected locations
- ✓ Configuration files load without errors
- ✓ Paths resolve correctly
- ✓ Git history preserved for moved files
- ✓ No duplicate files
- ✓ Documentation accurate
- ✓ Legacy compatibility maintained

### Common Issues and Solutions

**Issue**: `default_parameters` not found
**Solution**: Ensure `Scripts/Config` is on MATLAB path

**Issue**: "Old path references" still exist
**Solution**: Check for hardcoded paths in custom scripts

**Issue**: Tests fail
**Solution**: Verify tests are updated for new structure, or check if test is for deprecated functionality

**Issue**: UI won't open
**Solution**: Check UIController path setup, verify all UI dependencies accessible

## Manual Verification (if MATLAB unavailable)

If you don't have MATLAB available, you can still verify:

1. **File existence checks** (bash/shell)
2. **Git history verification** (git log --follow)
3. **Documentation review** (read README.md, FILE_MOVES.md)
4. **Path reference grep** (search for old paths)
5. **Directory structure check** (ls -la Scripts/)

## Automated Verification Script

For future PRs, consider adding this to CI:

```bash
#!/bin/bash
# verify_file_organization.sh

echo "Verifying file organization..."

# Check new directories exist
for dir in Config IO Grid Metrics Utils Methods/FiniteDifference; do
    if [ ! -d "Scripts/$dir" ]; then
        echo "✗ Missing directory: Scripts/$dir"
        exit 1
    fi
done

# Check old directories removed
for dir in Editable Infrastructure; do
    if [ -d "Scripts/$dir" ]; then
        echo "✗ Old directory still exists: Scripts/$dir"
        exit 1
    fi
done

# Check key files exist
files=(
    "Scripts/Config/default_parameters.m"
    "Scripts/Config/user_settings.m"
    "Scripts/IO/PathBuilder.m"
    "Scripts/Grid/ic_factory.m"
    "Scripts/Metrics/MetricsExtractor.m"
)

for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "✗ Missing file: $file"
        exit 1
    fi
done

echo "✓ File organization verified"
```

## Post-Verification Actions

After successful verification:
1. ✅ Mark verification checklist items complete
2. ✅ Update PR description with verification results
3. ✅ Request code review
4. ✅ Merge to main branch (after approval)
5. ✅ Notify team of new structure
6. ✅ Update any external documentation

## Questions or Issues?

If verification fails or you encounter issues:
1. Check `FILE_MOVES.md` for expected file locations
2. Review `PR_DESCRIPTION.md` for detailed changes
3. Check `Scripts/Config/README.md` for configuration help
4. Open an issue with specific error messages
