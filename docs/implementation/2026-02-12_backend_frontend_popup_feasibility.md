# Backend-Frontend Popup Feasibility (Task 305...43e5)

## Goal
- Assess whether MECH0020 can keep MATLAB as compute backend while using a richer popup frontend path, without turning into a separate project.

## Constraints (from task intent)
- Popup desktop experience, not web-only deployment.
- No heavy new runtime burden for normal users.
- Must remain operable from MATLAB and Python workflows.

## Spike Artifacts
- Probe script (MATLAB side): `tests/ui/probe_backend_frontend_bridge.m`
- Probe script (Python side): `prototypes/ui_bridge/python_backend_bridge_probe.py`
- Probe outputs:
  - `Artifacts/TestReports/UIBridgeProbe/bridge_probe_report_<timestamp>.md`
  - `Artifacts/TestReports/UIBridgeProbe/bridge_probe_output_<timestamp>.json`

## Candidate Paths
| Path | Complexity | UX headroom | Packaging risk | Notes |
| --- | --- | --- | --- | --- |
| MATLAB-only (`uifigure`) | Low | Medium | Low | Best for near-term velocity and test stability. |
| MATLAB backend + Python popup | Medium | High | Medium | Good bridge option for richer widgets with local desktop app behavior. |
| MATLAB backend + JS desktop wrapper | High | High | High | Strong UX potential but larger dependency and maintenance footprint. |

## Recommendation
- Keep current MATLAB UI as default production path.
- Use MATLAB->Python bridge as the first architecture extension only when a specific UI requirement is blocked in `uifigure`.
- Keep bridge isolated behind a probe/adapter boundary (no coupling into solver/dispatcher).

## Exit Criteria for This Task
- Evidence that MATLAB can hand telemetry to a Python process and receive normalized output.
- Documented decision that bounds complexity and preserves current workflow.
