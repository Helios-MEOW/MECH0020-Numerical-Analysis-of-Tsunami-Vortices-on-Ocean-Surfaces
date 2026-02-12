# UI Capability Decision Matrix (Task 305...9980)

## Scope
- Evaluate practical support for LaTeX text, animation, and figure behavior in current MATLAB UI.
- Compare UI path options for MECH0020 without forcing a full frontend rewrite.

## Probe Method
- Runtime probe script: `tests/ui/probe_ui_capabilities.m`
- Outputs expected:
  - `Artifacts/TestReports/UICapabilityProbe/ui_capability_probe_<timestamp>.json`
  - `Artifacts/TestReports/UICapabilityProbe/ui_capability_probe_<timestamp>.md`
  - `Artifacts/TestReports/UICapabilityProbe/ui_capability_uiaxes_<timestamp>.png`
  - `Artifacts/TestReports/UICapabilityProbe/ui_capability_classic_axes_<timestamp>.png`

## Capability Matrix
| Capability | uifigure/uiaxes | classic figure/axes | Notes |
| --- | --- | --- | --- |
| LaTeX axis labels/titles | Supported | Supported | Already used in monitor and IC preview flows. |
| Animated line updates | Supported | Supported | `animatedline` works in both probe paths. |
| Frame capture for reports | Supported | Supported | `getframe` + `imwrite` usable in probe pipeline. |
| Label-level LaTeX (`uilabel`) | Partial / limited | N/A | Depends on control interpreter support; axis labels are the reliable path. |

## Decision
- Keep MATLAB UI as primary runtime frontend for current project scope.
- Use `uiaxes` for math-rich labels and in-UI animation traces.
- Reserve cross-language popup frontend exploration as a later architecture spike (`305...43e5`) if control-level rendering constraints block required UX.

## Integration Guidance
- Prefer math labels on axes and plot annotations instead of relying on `uilabel` LaTeX.
- Keep animation lightweight in monitor loop to avoid UI lag under longer runs.
- Preserve current dispatcher/test contracts; treat frontend architecture exploration as isolated spike work.
