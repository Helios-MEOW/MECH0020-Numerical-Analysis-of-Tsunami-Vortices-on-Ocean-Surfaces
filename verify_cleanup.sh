#!/bin/bash
echo "============================================"
echo "Repository Cleanup Verification"
echo "============================================"
echo ""

# Check root directory
echo "1. ROOT DIRECTORY CHECK"
echo "   Expected: README.md, MECH0020_COPILOT_AGENT_SPEC.md, .gitignore"
root_files=$(ls -1 *.md *.txt 2>/dev/null | wc -l)
echo "   Root files (md/txt): $root_files"
if [ -f "README.md" ] && [ -f "MECH0020_COPILOT_AGENT_SPEC.md" ] && [ -f ".gitignore" ]; then
    echo "   ✓ Essential files present"
else
    echo "   ✗ Missing essential files"
fi
echo ""

# Check Scripts structure
echo "2. SCRIPTS DIRECTORY STRUCTURE"
for dir in Drivers Solvers Plotting Infrastructure UI Sustainability Editable; do
    if [ -d "Scripts/$dir" ]; then
        count=$(find "Scripts/$dir" -type f -name "*.m" | wc -l)
        echo "   ✓ Scripts/$dir/ exists ($count .m files)"
    else
        echo "   ✗ Scripts/$dir/ missing"
    fi
done
if [ -d "Scripts/Solvers/FD" ]; then
    count=$(find "Scripts/Solvers/FD" -type f -name "*.m" | wc -l)
    echo "   ✓ Scripts/Solvers/FD/ exists ($count .m files)"
else
    echo "   ✗ Scripts/Solvers/FD/ missing"
fi
echo ""

# Check entry points
echo "3. ENTRY POINTS"
if [ -f "Scripts/Drivers/Analysis.m" ]; then
    lines=$(wc -l < "Scripts/Drivers/Analysis.m")
    echo "   ✓ Scripts/Drivers/Analysis.m ($lines lines)"
else
    echo "   ✗ Scripts/Drivers/Analysis.m missing"
fi

if [ -f "Scripts/Drivers/run_adaptive_convergence.m" ]; then
    echo "   ✓ Scripts/Drivers/run_adaptive_convergence.m"
else
    echo "   ✗ Scripts/Drivers/run_adaptive_convergence.m missing"
fi

if [ -f "Scripts/Drivers/AdaptiveConvergenceAgent.m" ]; then
    echo "   ✓ Scripts/Drivers/AdaptiveConvergenceAgent.m"
else
    echo "   ✗ Scripts/Drivers/AdaptiveConvergenceAgent.m missing"
fi
echo ""

# Check old files removed
echo "4. OLD FILES REMOVED"
if [ ! -f "Scripts/Main/Analysis.m" ]; then
    echo "   ✓ Old Scripts/Main/Analysis.m removed"
else
    echo "   ✗ Old Scripts/Main/Analysis.m still exists"
fi

if [ ! -d "Scripts/Main" ]; then
    echo "   ✓ Scripts/Main/ directory removed"
else
    echo "   ✗ Scripts/Main/ still exists"
fi

if [ ! -d "Scripts/Methods" ]; then
    echo "   ✓ Scripts/Methods/ directory removed"
else
    echo "   ✗ Scripts/Methods/ still exists"
fi
echo ""

# Check tests
echo "5. TESTS DIRECTORY"
test_count=$(find tests -type f -name "*.m" | wc -l)
echo "   Test files in tests/: $test_count"
if [ $test_count -ge 8 ]; then
    echo "   ✓ All test files moved to tests/"
else
    echo "   ✗ Missing test files"
fi
echo ""

# Check documentation
echo "6. DOCUMENTATION"
if [ -d "docs/markdown_archive" ]; then
    archived=$(find docs/markdown_archive -type f \( -name "*.md" -o -name "*.txt" -o -name "*.ipynb" \) | wc -l)
    echo "   ✓ docs/markdown_archive/ exists ($archived files)"
else
    echo "   ✗ docs/markdown_archive/ missing"
fi
echo ""

# Check Data structure
echo "7. DATA DIRECTORIES"
if [ -d "Data/Input" ]; then
    echo "   ✓ Data/Input/ exists"
else
    echo "   ✗ Data/Input/ missing"
fi

if [ -d "Data/Output" ]; then
    echo "   ✓ Data/Output/ exists"
else
    echo "   ✗ Data/Output/ missing"
fi
echo ""

# Check .gitignore
echo "8. GITIGNORE CONFIGURATION"
if grep -q "Data/Output/" .gitignore; then
    echo "   ✓ Data/Output/ in .gitignore"
else
    echo "   ✗ Data/Output/ not in .gitignore"
fi

if grep -q "chat.json" .gitignore; then
    echo "   ✓ chat.json in .gitignore"
else
    echo "   ✗ chat.json not in .gitignore"
fi
echo ""

echo "============================================"
echo "Verification Complete"
echo "============================================"
