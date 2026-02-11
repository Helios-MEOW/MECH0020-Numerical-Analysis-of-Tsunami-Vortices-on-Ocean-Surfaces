# Repo Hardening Baseline (2026-02-11)

## Requested Baseline Constants (from execution packet)
- `TOTAL_EMPTY=733`
- `ROOT_EMPTY=49`
- `RESULTS_EMPTY=565`
- `FIGURES_EMPTY=68`
- `TESTS_EMPTY=51`
- `TEMP_LIKE_FILES=3`

## Fresh Snapshot at Save-First Time
- `TOTAL_EMPTY=734`
- `ROOT_EMPTY=49`
- `RESULTS_EMPTY=565`
- `FIGURES_EMPTY=68`
- `TESTS_EMPTY=51`
- `TEMP_LIKE_FILES=3`

## Note on Difference
`TOTAL_EMPTY` increased by 1 after creating `docs/implementation/` as part of the save-first step.

## Additional Findings
- Duplicate script basename:
  - `Scripts/Infrastructure/Utilities/Finite_Difference_Analysis.m`
  - `Scripts/Methods/FiniteDifference/legacy_fd/Finite_Difference_Analysis.m`
- Legacy output path drift remains in runtime:
  - `Scripts/Modes/mode_plotting.m` (`Data/Output/...` lookup)
  - `Scripts/Modes/Convergence/run_adaptive_convergence.m` (`Data/Output/...` write path)
- Temporary log files present at repo root:
  - `complete_test.log`
  - `full_test_detailed.log`
  - `test_output.log`
