#!/bin/bash
echo "============================================"
echo "MATLAB Path Verification"
echo "============================================"
echo ""

echo "1. CHECKING Scripts/Drivers/Analysis.m PATHS"
echo "   Expected paths:"
echo "   - Scripts/Drivers"
echo "   - Scripts/Solvers"
echo "   - Scripts/Solvers/FD"
echo "   - Scripts/Infrastructure/Builds"
echo "   - Scripts/Infrastructure/DataRelatedHelpers"
echo "   - Scripts/Infrastructure/Initialisers"
echo "   - Scripts/Infrastructure/Runners"
echo "   - Scripts/Infrastructure/Utilities"
echo "   - Scripts/Editable"
echo "   - Scripts/UI"
echo "   - Scripts/Plotting"
echo "   - Scripts/Sustainability"
echo "   - utilities"
echo ""
echo "   Found paths:"
grep "addpath" Scripts/Drivers/Analysis.m | grep -v "^%" | sed 's/^/   /'
echo ""

echo "2. CHECKING tests/Run_All_Tests.m PATHS"
echo "   Found paths:"
grep "addpath" tests/Run_All_Tests.m | grep -v "^%" | sed 's/^/   /'
echo ""

echo "3. CHECKING Scripts/Drivers/run_adaptive_convergence.m"
echo "   Checking for updated output directory:"
if grep -q "Data/Output" Scripts/Drivers/run_adaptive_convergence.m; then
    echo "   ✓ Uses Data/Output for results"
else
    echo "   ✗ May not use correct output directory"
fi
echo ""

echo "4. FILE REFERENCES IN Infrastructure"
echo "   Checking validate_simulation_parameters.m:"
if grep -q "Scripts/Solvers" Scripts/Infrastructure/Utilities/validate_simulation_parameters.m; then
    echo "   ✓ References Scripts/Solvers"
else
    echo "   ? May need path check"
fi
echo ""

echo "5. SOLVER FILE LOCATIONS"
echo "   FD Solver files:"
ls -1 Scripts/Solvers/FD/*.m | sed 's/^/   /'
echo ""
echo "   Other Solver files:"
ls -1 Scripts/Solvers/*.m | sed 's/^/   /'
echo ""

echo "============================================"
echo "Path Verification Complete"
echo "============================================"
