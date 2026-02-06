# Quick Start Guide - After Regression Fixes

## ✅ All Regressions Fixed

This guide shows you how to use the repository after all regression fixes have been applied.

---

## 🚀 Starting a Simulation

### Step 1: Navigate to Scripts/Main
```matlab
cd /path/to/MECH0020-repository/Scripts/Main
```

### Step 2: Launch Analysis
```matlab
Analysis  % or Analysis_New - both work the same now
```

### Step 3: Choose Your Mode

A **startup dialog** will appear:

```
┌─────────────────────────────────────┐
│  Choose Simulation Interface        │
│                                     │
│  How would you like to run?         │
│                                     │
│ [🖥️ UI Mode] [📊 Standard Mode]    │
└─────────────────────────────────────┘
```

#### Option A: Click **🖥️ UI Mode**
→ Opens 3-tab graphical interface:
  - **Tab 1**: Configuration (method, mode, IC, parameters)
  - **Tab 2**: Live Monitor (execution, metrics, progress)
  - **Tab 3**: Results & Figures (browse, query, export)

#### Option B: Click **📊 Standard Mode**
→ Runs command-line mode:
  - Dark theme monitor
  - ANSI-colored output
  - Live metrics display
  - No GUI required

---

## 📊 Running Adaptive Convergence

The intelligent mesh convergence agent (not a dumb grid sweep!) is now available:

```matlab
cd Scripts/Main
run_adaptive_convergence
```

### What It Does:
1. **Preflight Tests** - Runs simulations at N=16, 32, 64
2. **Pattern Learning** - Analyzes convergence rate and cost scaling
3. **Sensitivity Analysis** - Identifies which parameters matter most
4. **Adaptive Refinement** - Intelligently selects next mesh size
5. **Richardson Extrapolation** - Estimates error accurately
6. **Binary Search** - Final bracket refinement

### Output Files:
```
Results/Convergence_Study/
├── convergence_trace.csv       # Iteration history
├── convergence_metadata.mat    # Full results
├── learning_model.txt          # Summary report
└── preflight/                  # Preflight figures
```

---

## 🔧 Configuring Parameters

### Using Default Parameters (Recommended)

Edit `Scripts/Editable/Default_FD_Parameters.m`:
```matlab
function Parameters = Default_FD_Parameters()
    % ===== PHYSICS =====
    Parameters.nu = 0.001;      % Viscosity
    Parameters.Lx = 2 * pi;     % Domain X
    Parameters.Ly = 2 * pi;     % Domain Y
    
    % ===== GRID =====
    Parameters.Nx = 128;        % Grid points X
    Parameters.Ny = 128;        % Grid points Y
    Parameters.delta = 2;       % ⭐ Grid spacing scaling
    
    % ===== TIME =====
    Parameters.dt = 0.001;      % Timestep
    Parameters.Tfinal = 1.0;    % Final time
    
    % ===== IC =====
    Parameters.ic_type = 'Lamb-Oseen';
end
```

### Overriding in Script

```matlab
% Load defaults
Parameters = Default_FD_Parameters();

% Override specific values
Parameters.Nx = 256;
Parameters.Ny = 256;
Parameters.delta = 3;  % Wider initial condition
Parameters.nu = 1e-4;  % Higher viscosity
```

### Important Parameters:

| Parameter | Purpose | Example Values |
|-----------|---------|----------------|
| `Nx`, `Ny` | Grid resolution | 64, 128, 256, 512 |
| `delta` | IC spacing scale | 1, 2, 3 |
| `nu` | Viscosity | 1e-6, 1e-4, 1e-3 |
| `dt` | Timestep | 0.0001, 0.001, 0.01 |
| `Tfinal` | Simulation time | 0.5, 1.0, 5.0, 10.0 |
| `ic_type` | Initial condition | 'Lamb-Oseen', 'stretched_gaussian' |

---

## ✅ Verification

Run the verification script to check all fixes:

```matlab
verify_regression_fixes
```

Expected output:
```
========================================================================
  REGRESSION FIX VERIFICATION
========================================================================

[Test 1] Checking delta parameter in Default_FD_Parameters...
  ✓ PASS: delta = 2.00

[Test 2] Checking delta parameter in create_default_parameters...
  ✓ PASS: delta = 2.00

[Test 3] Checking UIController class and startup dialog...
  ✓ PASS: UIController exists with startup dialog

[Test 4] Checking AdaptiveConvergenceAgent class...
  ✓ PASS: AdaptiveConvergenceAgent.m exists

[Test 5] Checking run_adaptive_convergence script...
  ✓ PASS: run_adaptive_convergence.m exists

[Test 6] Checking helper functions in Analysis.m...
  ✓ PASS: All helper functions found

[Test 7] Checking Analysis_New.m has UI mode selector...
  ✓ PASS: Analysis_New.m has UI mode selector

========================================================================
  VERIFICATION SUMMARY
========================================================================

Tests Passed: 7/7

✓ ALL TESTS PASSED - Regression fixes verified!
```

---

## 📚 Documentation

- **PROJECT_README.md** - Main documentation (updated with all fixes)
- **REGRESSION_FIXES_SUMMARY.md** - Detailed fix documentation
- **NEW_ARCHITECTURE.md** - Architecture guide
- **MECH0020_COPILOT_AGENT_SPEC.md** - Authoritative specification

---

## 🎯 What Was Fixed

1. ✅ **UI Mode Selector** - Now in both Analysis.m and Analysis_New.m
2. ✅ **Delta Parameter** - Added to Default_FD_Parameters.m
3. ✅ **Convergence Agent** - Integrated with standalone runner
4. ✅ **README** - Fixed tab count (3 not 9), removed duplicates

---

## 💡 Tips

- **First time?** → Use UI Mode for interactive exploration
- **Production runs?** → Use Standard Mode for batch processing
- **Convergence study?** → Use run_adaptive_convergence
- **Need help?** → Check PROJECT_README.md or run verify_regression_fixes

---

## 🐛 Troubleshooting

**Q: Startup dialog doesn't appear**
A: Make sure you're running from Scripts/Main and UIController.m is on path

**Q: "delta field not found" error**
A: Update to latest commit - delta was added to Default_FD_Parameters.m

**Q: Convergence agent fails**
A: Ensure Analysis.m is on path (it has required helper functions)

**Q: README says 9 tabs but UI shows 3**
A: README was wrong - updated to correctly show 3 tabs

---

## 📧 Support

For issues or questions about these fixes, see REGRESSION_FIXES_SUMMARY.md
