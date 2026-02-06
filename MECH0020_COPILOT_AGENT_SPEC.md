# MECH0020 Copilot Agent Technical Specification (Authoritative)

**Purpose:** This file is the single “source of truth” prompt/spec for the GitHub Copilot coding agent working on the MECH0020 tsunami-vortex dissertation repository.

**Project reality:** MATLAB-first repo. Python is auxiliary (APIs / sensor integration / optional utilities), not the primary UI or orchestration layer.

---

## 0) Definitions

- **Method:** numerical method family (e.g., `FD`, `FFT/Spectral`, `FV`).
- **Mode:** experiment/run mode for a given method. **For FD, modes are fixed to:**
  1) `Evolution`
  2) `Convergence`
  3) `ParameterSweep`
  4) `Plotting`
- **Run type:** how the user runs the project:
  - **Standard mode:** command-line/driver mode with a **live execution monitor** (dark theme).
  - **UI mode:** MATLAB UI (3 tabs) that configures, runs, and inspects simulations.

---

## 1) Non-negotiable rules (must obey)

### 1.1 Single UI rule
- There must be **ONE** user UI: **MATLAB UI** only.
- Do **NOT** implement or maintain a separate Python/Qt/PySide UI.
- Python may exist only for:
  - API calls
  - sensor/telemetry communication
  - optional preprocessing utilities
  - never as the primary UI.

### 1.2 Architecture invariants
- Keep `Analysis.m` thin and method-agnostic.
- All solvers run through **one dispatcher**.
- All runs produce metrics via **one unified metrics extractor**.
- Separate:
  - configuration vs execution vs kernels vs instrumentation vs visuals.
- Generated artefacts must be isolated and gitignored by default.

### 1.3 Output preservation
- Refactors must not change solver outputs beyond defined tolerance unless explicitly requested.
- If any behavioural change is possible, run a smoke baseline and record comparison results.

### 1.4 Documentation + references policy
- No ASCII “box art” diagrams in READMEs or notebooks.
- Do not invent references.
- Do not auto-insert arbitrary citations.
- Instead, insert **explicit placeholders** where citations are required:
  - `[[REF NEEDED: <what claim?>]]`
  - `[[FIGURE PLACEHOLDER: <what image should be inserted?>]]`
- If the agent used web information, record it in a short “Sources consulted” bullet list **without** fabricating formal citations.

### 1.5 Testing rule (single entry point)
- Testing must have **one single master runner** entry point:
  - `tests/Run_All_Tests.m` (name can vary, but single entry point is mandatory).
- Test data / cases may live in a separate script/function:
  - `tests/Test_Cases.m` (or similar).
- The agent should run **targeted tests** while developing, but the repo’s canonical test execution is via the single master runner.

### 1.6 “Editable stuff” rule (user editability)
- All user-editable defaults and settings must be located in one obvious directory, e.g.:
  - `Scripts/Editable/`
- The user should not have to search core solvers to change defaults.

### 1.7 Script proliferation control
- Do **NOT** create a new file for every subfunction.
- Prefer:
  - local functions within the owning module, or
  - shared helper in `Scripts/Infrastructure/` only if reused ≥2 places.

---

## 2) Required deliverables

### 2.1 UI mode (MATLAB UI only): exactly 3 tabs
**Tab 1 — Setup / Configuration**
- All configurable settings (method, mode, parameters, settings).
- Initial-condition preview (at least for FD ICs; other methods optional).
- Validation of parameters before run.

**Tab 2 — Live Execution**
- Live execution monitor (dark theme)
- Convergence monitor (when relevant, e.g., Convergence mode)
- Metrics panel (robust, interpretable, well-labeled)
- MATLAB “terminal” panel on the **right**, showing colored log output (must preserve existing color semantics if already implemented).

**Tab 3 — Results / Post-processing**
- Browse results using run IDs and metadata
- Select run → load plots / metrics / report
- Filters/query by: Method, Mode, Run ID, date/time, key parameters
- Optional: “Recreate run from figure name” workflow (see §4.4)

### 2.2 Standard mode: Live execution monitor (dark theme)
- When run without the UI, provide a **dark-themed** live monitor.
- Must show:
  - Method, Mode, Initial Condition
  - Step, physical time, dt
  - Grid info (Nx, Ny, dx, dy)
  - Stability/health metrics (CFL, max|ω|, etc.)
- Improve layout: group metrics into sections and maintain stable alignment.

### 2.3 Parameter and settings structures (succinct, consistent)
Implement a **clear struct schema** (names can vary, but separation must exist):

- `Parameters` — physics + numerics (scientific knobs)
- `Settings` — IO, UI/monitor toggles, logging, plotting policy (operational knobs)
- `Run_Config` — method/mode/IC/run_id paths
- `Run_Status` — live updates (timestep state, derived metrics, progress)

`Parameters` and `Settings` must be defined in one go (use `struct(...)` patterns), not 1-by-1 assignments.

### 2.4 Directory + artefact structure (FD is authoritative baseline)
The simulation must:
- check required directories exist
- create them if missing (idempotent)

#### FD directory structure requirements
For method `FD`, within the artefacts root (e.g., `Results/FD/`):

**Evolution**
- `Results/FD/Evolution/<run_id>/`
  - `Figures/Evolution/`
  - `Figures/Contours/`
  - `Figures/Vector/`
  - `Figures/Streamlines/`
  - `Figures/Animation/`
  - `Reports/`
  - `Data/` (heavy MAT/HDF5 if needed)

**Convergence**
- `Results/FD/Convergence/<study_id>/`
  - `Evolution/`
  - `MeshContours/`
  - `MeshGrids/`
  - `MeshPlots/`
  - `ConvergenceMetrics/`
  - `Reports/`

**ParameterSweep**
- `Results/FD/ParameterSweep/<study_id>/`
  - `<parameter_name_1>/Figures/...`
  - `<parameter_name_2>/Figures/...`
  - `Reports/`
  - `Data/`

**Plotting**
- `Results/FD/Plotting/`
  - one directory per figure family/type (since there will be many)

> Animation is a **setting**, not a mode.

#### Spectral / FV suggested structure
Mirror the FD pattern by method:
- `Results/FFT/Evolution/...`
- `Results/FV/ParameterSweep/...`
Use the same run_id and report conventions.

### 2.5 Reports (ANSYS/Abaqus-inspired)
For each run or study, generate a professional text-based report:
- `Report.txt` or `Report.md` (choose one; keep consistent)
- Must include:
  - Run metadata (timestamp, git commit hash if available, MATLAB version, OS)
  - Method/Mode/IC
  - Key parameters + settings summary (human-readable)
  - Derived metrics summary
  - File manifest (where outputs are stored)
  - Notes/warnings

### 2.6 Master runs table + Excel-friendly formatting
- Maintain a single **master** runs table across all methods/modes:
  - `Results/Runs_Table.csv` (append-safe).
- Optionally generate an `.xlsx` version **if available**:
  - Apply conditional formatting for key metrics if platform supports it.
  - Must degrade gracefully on platforms where Excel automation is not available.

### 2.7 “Plot-from-CSV” and “Recreate run from PNG” workflows
- Provide a query utility that selects runs by keys, e.g.:
  - Method=FD, Mode=Evolution, Run=2, IC=LambOseen
- Provide a “recreate from PNG” utility:
  1) user selects a PNG
  2) parse filename → `run_id`
  3) locate saved config (`Config.mat`)
  4) rerun (or regenerate plots) deterministically

This requires a run_id and file naming convention (§4.3–§4.4).

---

## 3) Implementation constraints and preferred patterns

### 3.1 Keep `Analysis.m` thin
- `Analysis.m` selects Run_Config, calls dispatcher, and returns results/paths.
- Mode-specific orchestration lives in mode modules, not in Analysis.

### 3.2 Mode modules are first-class but not bloated
- Each mode should be its own **function file** (preferred over scripts):
  - e.g., `FD_Evolution_Mode.m`, `FD_Convergence_Mode.m`, ...
- Each mode file may contain local functions for its internal needs.
- Only split helpers into separate files if reused ≥2 places.

### 3.3 Instrumentation entry points (single interface)
- One monitor interface callable by any solver/mode:
  - `Monitor_Start(Run_Config, Settings)`
  - `Monitor_Update(Run_Status)`
  - `Monitor_Stop(Run_Summary)`

### 3.4 Colored terminal output in UI
MATLAB standard controls may not support rich text colors. Use a robust approach:
- prefer `uihtml` (HTML rendering) for colored logs
- otherwise, degrade to monochrome but keep severity tags like `[INFO]`, `[WARN]`, `[ERROR]`.

### 3.5 Metrics (minimum recommended set)
- CFL (max, maybe percentile)
- max|ω|, mean|ω|
- enstrophy (and its time derivative if helpful)
- kinetic energy estimate (if velocity computed)
- residual / iteration error for Poisson/streamfunction solves
- wall time per step and ETA
- for convergence: QoI vs mesh (order estimate, asymptote estimate)

---

## 4) Run ID and file naming system

### 4.1 Run ID requirements
A run_id must be:
- unique
- reproducible and parseable
- short enough for file names
- encode method + mode + IC + key grid/time parameters (as needed)

### 4.2 Recommended strategy
- Run ID core:
  - timestamp (UTC) + method + mode + IC + short hash of config
- Example:
  - `20260206T000501Z_FD_Evolution_LambOseen_g256_dt1e-3_hA1B2`

### 4.3 File name format (figures)
All figure files must include run_id:
- `<run_id>__<figure_type>__<frame_or_variant>.png`

### 4.4 Recreate-from-PNG algorithm (must work)
1) parse run_id from filename
2) locate `Results/<method>/<mode>/<run_id>/Config.mat`
3) load config and recreate run (or regenerate plots)

---

## 5) Testing specification

### 5.1 Single master runner
`tests/Run_All_Tests.m` must:
- run all methods (as available) and all modes (FD: 4 modes)
- run both Standard mode (CLI) and UI mode (headless where possible)
- produce a single pass/fail summary and optionally JUnit-like output if desired

### 5.2 Test cases file
`tests/Test_Cases.m` provides:
- minimal configurations for quick tests
- “golden” micro-cases for regression
- keeps tests deterministic (fixed seeds)

### 5.3 Development workflow (agent behaviour)
- During implementation: run targeted tests for the changed area.
- Before finishing: run the master runner.

---

## 6) Documentation updates required (READMEs + notebook)

### 6.1 READMEs
- Update docs that currently assume dual UI or 9 tabs.
- Include:
  - how to run Standard mode
  - how to run UI mode (3 tabs)
  - where to edit defaults (`Scripts/Editable/`)
  - where outputs are stored (directory conventions)
- No ASCII diagrams; use headings + bullet lists and insert placeholders for screenshots.

### 6.2 Jupyter notebook revamp
- Create a clear structure:
  1) Overview & objectives
  2) Governing equations (brief; details elsewhere)
  3) Discretisation overview (brief)
  4) Methods & modes (FD baseline, then others)
  5) Validation & convergence philosophy
  6) Results gallery placeholders
  7) Reference placeholder section

- For any claim needing a citation:
  - add `[[REF NEEDED: ...]]`
- For any figure needed:
  - add `[[FIGURE PLACEHOLDER: ...]]`

---

## 7) Copilot agent operational workflow (GitHub)

### 7.1 Branch + PR policy
- Make all changes on a branch named:
  - `copilot/<short-task-name>`
- Open a **draft PR** targeting the chosen base branch.
- The PR must include:
  - a concise summary
  - test evidence (what ran, what passed)
  - a checklist of deliverables completed
  - references placeholders (not fabricated citations)

### 7.2 Do not ask the user “what next” mid-task
- The prompt is authoritative. Execute the full spec and produce the PR.
- Only ask questions if blocked by missing critical information.

---

## 8) Definition of done (DoD)

A task is “done” only when:
- MATLAB UI is the sole UI, with 3 tabs implemented as specified
- Standard mode monitor shows Method/Mode/IC and key metrics in dark theme
- Modes and directory structure match the FD baseline requirements
- Reports are generated per run/study
- Master runs table is append-safe and includes all required metadata
- Recreate-from-PNG works (at least for FD Evolution)
- Single master test runner exists and passes on minimal test cases
- READMEs + notebook updated with placeholders (no ASCII art) and no fabricated citations
- All changes are presented in a draft PR on a `copilot/...` branch

---

## 9) Notes for the agent (avoid common failure modes)

- Do not create a Python UI to “help” the MATLAB UI.
- Do not multiply config locations; keep user-editable defaults in one obvious directory.
- Do not create a new file for every helper; prefer local functions or shared Infrastructure helpers if reused.
- Do not hardcode paths; generate via a central path-builder that creates directories as needed.
- Do not invent citations; insert placeholders.
