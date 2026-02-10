# Quick Start Guide - Scripts Directory Organization

**January 31, 2026** - All scripts organized into functional directories with comprehensive documentation.

## 🎯 Start Here

### Option 1: Quick Simulation (5 minutes)
```matlab
% 1. Navigate to main scripts
cd Analysis/Scripts/Main/

% 2. Run test framework (verify setup)
TEST_FRAMEWORK()

% 3. Run quick simulation
Parameters.mode = 'test_convergence';
Analysis()
```

### Option 2: Understanding the Structure (10 minutes)
```
1. Read: Analysis/Scripts/README.md
   ↓
2. Choose your interest:
   - Run simulations? → Read Scripts/Main/README.md
   - Understand solver? → Read Scripts/Methods/README.md
   - Monitor energy? → Read Scripts/Sustainability/README.md
   - Check dashboard? → Read Scripts/Visuals/README.md
```

### Option 3: Production Run with Full Features (15 minutes)
```matlab
cd Analysis/Scripts/Main/

% Configure for your needs
Parameters.mode = 'solve';
Parameters.Nx = 256;           % High resolution
Parameters.Ny = 256;
Parameters.nu = 0.001;
Parameters.dt = 0.01;
Parameters.Tfinal = 100;
Parameters.live_preview = true;        % Live dashboard
Parameters.energy_monitoring = true;   % Track energy
Parameters.progress_stride = 10;

% Run analysis
Analysis()

% Results saved to Analysis/Results/
```

## 📁 Directory Quick Reference

| Path | Purpose | Quick Start |
|------|---------|-------------|
| `Scripts/Main/` | Run simulations | `cd Scripts/Main && Analysis()` |
| `Scripts/Methods/` | Study numerical methods | Read README.md for theory |
| `Scripts/Sustainability/` | Monitor energy usage | See ENERGY_INTEGRATION_TEMPLATE.m |
| `Scripts/Visuals/` | Live progress dashboard | Auto-creates with Analysis.m |

## 🎓 By Experience Level

### Beginner
1. Read: [Scripts/README.md](Scripts/README.md)
2. Go to: [Scripts/Main/](Scripts/Main/)
3. Read: [Scripts/Main/README.md](Scripts/Main/README.md)
4. Run: `Analysis()` with default parameters
5. Check the live dashboard that appears

### Intermediate
1. Read: [Scripts/Main/README.md](Scripts/Main/README.md) in detail
2. Modify Parameters (lines 118-180 in Analysis.m)
3. Try different execution modes:
   - `mode = 'animate'`
   - `mode = 'sweep'`
   - `mode = 'convergence_search'`
4. Analyze results in `Analysis/Results/`

### Advanced
1. Read: [Scripts/Methods/README.md](Scripts/Methods/README.md)
2. Study: [Scripts/Methods/Finite_Difference_Analysis.m](Scripts/Methods/Finite_Difference_Analysis.m)
3. Read: [Scripts/Sustainability/README.md](Scripts/Sustainability/README.md)
4. Integrate energy monitoring (see ENERGY_INTEGRATION_TEMPLATE.m)
5. Build custom workflows

## 📊 What Each Script Does

| Script | Location | What It Does |
|--------|----------|--------------|
| **Analysis.m** | Scripts/Main/ | Main driver - orchestrates all simulations (7 modes) |
| **TEST_FRAMEWORK.m** | Scripts/Main/ | Verifies energy monitoring system is working |
| **Finite_Difference_Analysis.m** | Scripts/Methods/ | Solves 2D Navier-Stokes with finite differences |
| **EnergySustainabilityAnalyzer.m** | Scripts/Sustainability/ | Models energy consumption vs complexity |
| **HardwareMonitorBridge.m** | Scripts/Sustainability/ | Monitors CPU, memory, power during runs |
| **update_live_monitor.m** | Scripts/Sustainability/ | Updates progress dashboard in real-time |
| **ENERGY_INTEGRATION_TEMPLATE.m** | Scripts/Sustainability/ | Shows how to integrate energy monitoring |
| **create_live_monitor_dashboard.m** | Scripts/Visuals/ | Creates the live progress dashboard |

## ⚡ Common Tasks

### "I want to run a simulation"
```matlab
cd Analysis/Scripts/Main
Analysis()              % Uses default parameters
% Or with custom settings:
Parameters.Nx = 256;
Parameters.mode = 'animate';
Analysis()
```

### "I want to understand how the solver works"
```
1. Read: Analysis/Scripts/Methods/README.md
2. Open: Analysis/Scripts/Methods/Finite_Difference_Analysis.m
3. Key sections: A (plots), B (solver), C (setup)
```

### "I want to track energy consumption"
```matlab
cd Analysis/Scripts/Main
Parameters.energy_monitoring = true;
Analysis()
% Results in Analysis/Results/*_energy.mat
```

### "I want to test if everything works"
```matlab
cd Analysis/Scripts/Main
TEST_FRAMEWORK()
% Verifies Python, psutil, and monitoring system
```

### "I want to visualize my results"
```
The live dashboard appears automatically when running Analysis.m
6 panels show:
- Progress bar
- Execution timeline
- Iteration speed
- System resources
- Problem configuration
- Key physical metrics
```

### "I want to see the code organization"
```matlab
% All scripts use %% section headers (visible in MATLAB outline)
% Press Ctrl+Shift+O (Windows) to open outline
% Or use Editor → Go To... → Go To Line
```

## 📖 Documentation Files

```
Analysis/
├── SCRIPTS_ORGANIZATION_COMPLETE.md    ← Full summary of setup
├── SCRIPTS_VISUAL_OVERVIEW.md          ← Directory tree & features
├── QUICK_START_GUIDE.md                ← This file
├── Scripts/README.md                   ← Master guide
├── Scripts/Main/README.md              ← Execution guide
├── Scripts/Methods/README.md           ← Solver theory
├── Scripts/Sustainability/README.md    ← Energy tools
├── Scripts/Visuals/README.md           ← Dashboard guide
└── Scripts/*/                          ← Script directories
```

## 🔍 File Organization Principles

1. **Logical Grouping**: Scripts organized by function
   - Main: Execution
   - Methods: Numerical solutions
   - Sustainability: Energy monitoring
   - Visuals: Dashboard & monitoring

2. **Consistent Standards**: All scripts follow
   - `%%` section headers (MATLAB outline)
   - `%` single-line comments
   - Semantic function organization
   - Comprehensive documentation

3. **Easy Navigation**: Every directory has
   - README.md with detailed guide
   - Cross-references to related files
   - Code examples and usage
   - Troubleshooting section

## ✅ Verification Checklist

After completing setup, verify:

- [ ] Can navigate to `Scripts/Main/` directory
- [ ] `Analysis.m` is present (4,141 lines)
- [ ] `TEST_FRAMEWORK.m` is present (107 lines)
- [ ] Can run `TEST_FRAMEWORK()` successfully
- [ ] Can run `Analysis()` with default parameters
- [ ] Live dashboard appears (6 monitoring panels)
- [ ] Results save to `Analysis/Results/`
- [ ] Can read `Scripts/README.md` successfully
- [ ] All 4 subdirectories exist (Main, Methods, Sustainability, Visuals)
- [ ] Each subdirectory has README.md

## 🚀 Next Steps

1. **Immediate**: Read Scripts/README.md (5 min)
2. **Quick**: Run TEST_FRAMEWORK() (2 min)
3. **Test**: Run Analysis() with small grid (5-10 min)
4. **Learn**: Read Scripts/Main/README.md (10 min)
5. **Explore**: Try different execution modes (15 min)
6. **Advanced**: Study Scripts/Methods/ (30 min)
7. **Integrate**: Add energy monitoring (15 min)

## 💡 Pro Tips

**Tip 1**: Use MATLAB Editor Outline (Ctrl+Shift+O) to navigate large scripts
```matlab
% All scripts have %% section headers visible in outline
% Quickly jump to sections: A, B, C, etc.
```

**Tip 2**: Run TEST_FRAMEWORK first to catch setup issues
```matlab
TEST_FRAMEWORK()  % ~10 seconds, verifies everything
```

**Tip 3**: Start with small grid sizes for testing
```matlab
Parameters.Nx = 64;   % Small, fast (~5 seconds)
Parameters.Ny = 64;
Analysis()
```

**Tip 4**: Enable live preview only if monitoring is needed
```matlab
Parameters.live_preview = true;   % Shows dashboard (1% overhead)
Parameters.live_stride = 50;      % Update every 50 iterations
```

**Tip 5**: Save energy monitoring data for later analysis
```matlab
Parameters.energy_monitoring = true;
Analysis()
% Data saved to Results/ for later analysis
```

## 🆘 Troubleshooting

**Problem**: Can't find Scripts directory
```
Solution: 
- Scripts/ should be in Analysis/ directory
- Check path: Analysis/Scripts/
- See SCRIPTS_ORGANIZATION_COMPLETE.md
```

**Problem**: TEST_FRAMEWORK fails
```
Solution:
- Check Python installation (python --version)
- Check psutil: pip install psutil
- Read Scripts/Main/README.md troubleshooting section
```

**Problem**: Analysis.m doesn't run
```
Solution:
- Check you're in Scripts/Main/ directory
- Check all parameters are valid
- Try Parameters.mode = 'test_convergence' for quick test
- Read Scripts/Main/README.md
```

**Problem**: Dashboard doesn't appear
```
Solution:
- Dashboard auto-creates when Analysis() runs
- Check Parameters.live_preview = true
- MATLAB R2021a or later required
- See Scripts/Visuals/README.md
```

**Problem**: Energy monitoring fails
```
Solution:
- Run TEST_FRAMEWORK() to diagnose
- Check Python/psutil installation
- See Scripts/Sustainability/README.md troubleshooting
```

## 📞 Getting Help

1. **Quick Questions**: Check relevant README.md file
2. **Theory**: See Scripts/Methods/README.md
3. **Configuration**: See Scripts/Main/README.md
4. **Energy Monitoring**: See Scripts/Sustainability/README.md
5. **Dashboard**: See Scripts/Visuals/README.md
6. **Issues**: Check troubleshooting sections in READMEs

## 🎉 You're All Set!

Your scripts are now:
- ✅ Professionally organized
- ✅ Well documented
- ✅ Easy to navigate
- ✅ Ready for production use
- ✅ Ready for team collaboration
- ✅ Ready for GitHub publication

**Start with**: `cd Analysis/Scripts/Main && Analysis()`

---

**Created**: January 31, 2026
**Total Scripts**: 8 files, ~6,578 lines of code
**Documentation**: 5 comprehensive README files + guides
**Status**: ✅ Complete and ready to use
