#!/bin/bash
# Verify all 9 critical fixes are present in static_analysis.m

echo "═══════════════════════════════════════════════════════════════"
echo "  VERIFYING 9 CRITICAL FIXES IN static_analysis.m"
echo "═══════════════════════════════════════════════════════════════"
echo ""

FILE="static_analysis.m"

# Fix #1: Invalid Parameter Removal
echo "[1/9] Checking Fix #1: Invalid 'Ignorecase' parameter removal..."
if grep -q "filepath_lower = lower(filepath)" "$FILE" && \
   ! grep -q "'Ignorecase', true" "$FILE"; then
    echo "✓ PASS: Using lowercase comparison instead of invalid param"
else
    echo "✗ FAIL: Invalid parameter may still exist"
fi
echo ""

# Fix #2: Cell Array Accumulation
echo "[2/9] Checking Fix #2: Cell array accumulation instead of growing arrays..."
if grep -q "issues_cell = cell(0)" "$FILE" && \
   grep -q "issues_cell{end+1}" "$FILE" && \
   grep -q "vertcat(issues_cell{:})" "$FILE"; then
    echo "✓ PASS: Using cell array accumulation"
else
    echo "✗ FAIL: May still be using growing arrays"
fi
echo ""

# Fix #3: Global Issue ID
echo "[3/9] Checking Fix #3: Global issue ID counter..."
if grep -q "global_issue_id = 0" "$FILE" && \
   grep -q "global_issue_id = global_issue_id + 1" "$FILE"; then
    echo "✓ PASS: Using global issue counter"
else
    echo "✗ FAIL: May have duplicate IDs"
fi
echo ""

# Fix #4: Consolidated Writing Comments
echo "[4/9] Checking Fix #4: Updated comments (no 'incremental')..."
if grep -q "consolidated at end" "$FILE" && \
   ! grep -q "incremental" "$FILE"; then
    echo "✓ PASS: Comments updated to 'consolidated'"
else
    echo "✗ FAIL: Misleading 'incremental' comments may still exist"
fi
echo ""

# Fix #5: Report/Gate Mode Split
echo "[5/9] Checking Fix #5: Report/Gate mode split with FailOnIssues..."
if grep -q "'FailOnIssues', false" "$FILE" && \
   grep -q "if opts.FailOnIssues" "$FILE"; then
    echo "✓ PASS: Report/Gate mode implemented"
else
    echo "✗ FAIL: Mode split not implemented"
fi
echo ""

# Fix #6: File Count Reconciliation
echo "[6/9] Checking Fix #6: File count reconciliation..."
if grep -q "report.file_counts" "$FILE" && \
   grep -q "'found'" "$FILE" && \
   grep -q "'analyzed'" "$FILE" && \
   grep -q "'excluded'" "$FILE" && \
   grep -q "'errors'" "$FILE"; then
    echo "✓ PASS: File count reconciliation structure present"
else
    echo "✗ FAIL: File count reconciliation missing"
fi
echo ""

# Fix #7: Per-File Terminal Output with Impact
echo "[7/9] Checking Fix #7: Per-file terminal output with impact labels..."
if grep -q "RUNTIME_ERROR_LIKELY" "$FILE" && \
   grep -q "LOGIC_RISK" "$FILE" && \
   grep -q "PERFORMANCE_STYLE" "$FILE" && \
   grep -q "impact" "$FILE"; then
    echo "✓ PASS: Impact labels implemented"
else
    echo "✗ FAIL: Impact labels missing"
fi
echo ""

# Fix #8: SA-RUNTIME-0001 Issue Code
echo "[8/9] Checking Fix #8: SA-RUNTIME-0001 instead of ANLZ-001/002..."
if grep -q "SA-RUNTIME-0001" "$FILE" && \
   ! grep -q "ANLZ-001" "$FILE" && \
   ! grep -q "ANLZ-002" "$FILE"; then
    echo "✓ PASS: Using SA-RUNTIME-0001 for analyzer errors"
else
    echo "✗ FAIL: Old ANLZ codes may still exist"
fi
echo ""

# Fix #9: checkcode -struct flag
echo "[9/9] Checking Fix #9: checkcode call with -struct flag..."
if grep -q "checkcode(filepath, '-id', '-struct')" "$FILE"; then
    echo "✓ PASS: Using -struct flag in checkcode"
else
    echo "✗ FAIL: -struct flag not used"
fi
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "  VERIFICATION COMPLETE"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Line count check
LINES=$(wc -l < "$FILE")
echo "File has $LINES lines (target: 900-1000)"
if [ "$LINES" -ge 900 ] && [ "$LINES" -le 1000 ]; then
    echo "✓ Line count within target range"
else
    echo "⚠ Line count outside target range"
fi
