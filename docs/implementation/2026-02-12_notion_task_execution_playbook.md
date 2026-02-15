# MECH0020 Notion Task Execution & Integration Playbook (2026-02-12)

## 1) Purpose
This playbook defines a strict, repeatable workflow for executing **every task** in the Notion MECH0020 Goals workspace while preserving stability of already completed features.

It is designed to support:
- Full task-by-task delivery from Notion task and note databases.
- Deterministic planning before implementation.
- Incremental, test-backed fixes.
- Regression protection for previously completed items.
- Commit-per-task traceability.

---

## 2) Notion Workspace Operating Model
Use two linked databases under the MECH0020 Goals page:

### A. `Implementation Tasks`
Required fields:
- `Task` (title)
- `Status` (select): `Backlog`, `Planned`, `In Progress`, `Blocked`, `Review`, `Done`
- `Priority` (select): `P0`, `P1`, `P2`, `P3`
- `Area` (multi-select): `UI`, `Driver`, `Solver`, `Methods`, `Plotting`, `Infrastructure`, `Docs`, `Tests`
- `Source Note` (relation to Notes DB)
- `Acceptance Criteria` (text)
- `Integration Risks` (text)
- `Verification Commands` (text)
- `PR/Commit` (text)
- `Regression Scope` (text)
- `Last Verified` (date)

### B. `Implementation Notes`
Required fields:
- `Note` (title)
- `Type` (select): `User Note`, `Agent Update`, `Research`, `Bug Trace`, `Decision`
- `Related Tasks` (relation to Tasks DB)
- `Signals / Evidence` (text)
- `Proposed Actions` (text)
- `Confidence` (select): `High`, `Medium`, `Low`

---

## 3) End-to-End Task Lifecycle (Mandatory)
For each task row, execute the following sequence without skipping steps:

1. **Intake & Clarify**
   - Link all relevant notes to task row.
   - Convert note claims into explicit acceptance criteria.
   - Identify touched files/components and runtime modes.

2. **Plan Before Code**
   - Add a mini implementation plan in the task row:
     - Root cause hypothesis.
     - Minimal change set.
     - Test plan (unit/integration/UI/manual).
     - Rollback plan.

3. **Implement Smallest Safe Fix**
   - Keep scope tightly aligned to acceptance criteria.
   - Prefer localised changes over broad refactors.

4. **Verify & Iterate**
   - Run listed verification commands.
   - If failure persists, update hypothesis and patch again.
   - Repeat until all acceptance criteria pass.

5. **Regression Guard**
   - Re-run baseline checks for previously completed work.
   - Confirm no behavior regressions in the affected subsystem(s).

6. **Document Evidence**
   - Record exact commands + outcomes.
   - Log output artifact paths (reports, figures, test logs).

7. **Commit & Link Back**
   - Commit once task is green.
   - Record commit hash/PR reference in Notion task row.

8. **Close Task**
   - Set `Status = Done` only if acceptance + regression checks both pass.

---

## 4) Task Execution Template (Copy into each Notion task)

```md
## Execution Plan
### Problem Statement
- 

### Scope
- In scope:
- Out of scope:

### Root Cause Hypothesis
- 

### Change Plan
1.
2.
3.

### Verification Plan
- Primary checks:
- Regression checks:
- Artifacts expected:

### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### Integration Risks
- Risk:
  - Mitigation:

### Exit Conditions
- [ ] All acceptance criteria pass
- [ ] Regression suite passes for touched areas
- [ ] Commit created and linked
```

---

## 5) Repeatable Command Strategy
Use a two-layer verification pattern per task:

1. **Focused checks** for touched area.
2. **Safety-net checks** for known completed features.

Recommended baseline command set (adapt per task):
- MATLAB non-interactive smoke run for edited workflow.
- Existing script/test command for targeted mode.
- Regression rerun of prior completed feature checks.
- Optional UI acceptance flow when UI-impacting changes occur.

Record command strings and pass/fail result in Notion.

---

## 6) Regression Protection Matrix
When a task touches one area, validate these dependent areas before closure:

- **UIController / UI layout** changes:
  - Launch pipeline routing.
  - IC preview parity.
  - Mode-specific visibility logic.

- **Driver / dispatcher** changes:
  - Evolution, convergence, sweep, animation, experimentation mode routing.

- **Initial conditions / coefficients** changes:
  - `initialise_omega` compatibility.
  - Preview-vs-launch consistency.

- **Infrastructure/path/reporting** changes:
  - Canonical output path discipline.
  - Report payload generation.
  - Sustainability ledger continuity.

---

## 7) Prioritization Order for Full Backlog Burn-down
Process tasks in this sequence to minimize rework:

1. **Blockers** (prevent launch or core runs).
2. **Correctness bugs** (wrong physics/semantics/output).
3. **Integration consistency** (preview-launch mismatch, mode mismatch).
4. **Reliability hardening** (guards, validation, fail-fast messaging).
5. **UX/quality-of-life** improvements.
6. **Documentation and housekeeping**.

Within each bucket: execute highest risk + highest dependency tasks first.

---

## 8) Definition of Done (Strict)
A task is only Done if all are true:
- Acceptance criteria are explicitly checked.
- Verification commands are logged and green.
- Regression checks for completed features are green.
- A commit exists and is linked.
- Notes are updated with final solution and evidence.

---

## 9) Cadence for Systematic Execution
Run this cycle continuously:
1. Pull next `Planned` task.
2. Move to `In Progress`.
3. Execute lifecycle in Section 3.
4. Commit + update Notion.
5. Move task to `Done`.
6. Repeat until backlog = 0.

Use one task per commit by default for clean traceability.

---

## 10) Handling Previously Completed Tasks
For tasks already marked done:
- Re-validate only when new changes touch their dependency surface.
- Keep a lightweight regression checklist row linked to each completed task.
- If regression appears, reopen task with `Status = In Progress` and attach failing evidence.

This enforces forward progress while preventing silent breakage.
