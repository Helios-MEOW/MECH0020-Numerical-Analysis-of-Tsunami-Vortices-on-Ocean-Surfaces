# Legacy Archive Notes

## 2026-02-11 naming cleanup

- Canonical legacy FD analysis location: `Scripts/Methods/FiniteDifference/legacy_fd/Finite_Difference_Analysis.m`
- Removed duplicate utility-copy path from active utilities area to avoid ambiguous source-of-truth naming.
- Relocated UI test artifact from production UI folder to test scope:
  - from `Scripts/UI/TEST_UIController.m`
  - to `tests/ui/TEST_UIController.m`
