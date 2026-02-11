# Repo Hardening Execution Plan (2026-02-11)

## Summary
This execution packet is implemented in phases with sequential commits.

Canonical storage:
1. Repo canonical file: `docs/implementation/2026-02-11_repo_hardening_execution_plan.md`
2. Notion mirror under `MECH0020`: `MECH0020 Simulation Program Hub` with linked `Implementation Tasks` and `Research Findings`

## Save-First Steps
1. Create `docs/implementation/2026-02-11_repo_hardening_execution_plan.md` (this file).
2. Create `docs/implementation/2026-02-11_repo_hardening_baseline.md`.
3. Mirror this plan to Notion under `MECH0020`.
4. Create Notion DB: `Implementation Tasks` and seed phase/subtask rows.
5. Create Notion DB: `Research Findings` and seed report/media/sustainability research rows.

## Phase Execution Order (sequential commits)
1. `chore(checkpoint): baseline snapshot before implementation`
2. `docs(notebook): rebuild self-contained notebook for currently executable methods`
3. `docs(readme): rewrite root README with current architecture and mermaid flows`
4. `chore(cleanup): remove residual and temp artifacts`
5. `refactor(paths): enforce canonical Results-root output paths`
6. `refactor(naming): archive legacy duplicates and disambiguate scripts`
7. `docs(code): add targeted explanatory comments`
8. `feat(media): add video format MWE and set MP4(H.264) default`
9. `feat(reports): unified report payload + Quarto HTML/PDF pipeline`
10. `feat(sustainability): always-on run ledger with machine tagging`
11. `test(integration): add regression suite for paths, reports, media, sustainability`
12. `docs(legacy): archive stale docs and add redirects`

## Public API / Interface Changes
1. `Scripts/Editable/Settings.m` gains normalized sections:
`output_root`, `reporting.*`, `media.*`, `sustainability.*`.
2. `Scripts/Editable/Parameters.m` gains normalized `media.*` and report template selectors.
3. `PathBuilder.get_run_paths` standardizes run subtree:
`Config`, `Data`, `Figures`, `Media`, `Reports`, `Logs`, `Sustainability`.
4. New per-run metadata file: `run_manifest.json`.
5. New global sustainability ledger: `Results/Sustainability/runs_sustainability.csv`.
6. New report input: `report_payload.json`.

## Test Cases / Acceptance
1. No run writes outside canonical `Results` or `Artifacts/tests`.
2. Plotting mode resolves source runs from canonical paths only.
3. Every report-enabled run produces both HTML and PDF reports.
4. Every run appends one sustainability ledger row with non-empty `run_id` and `machine_id`.
5. Media MWE produces MP4 with configured fps/quality; GIF is fallback only.
6. Notebook runs in a clean session and reflects true runnable method scope.
7. README examples and paths match runtime behavior.

## Assumptions / Defaults
1. Notebook “run any method” means all currently executable methods; placeholders are explicit.
2. Report stack default: Quarto (HTML + PDF).
3. Animation default: MP4 (H.264); GIF retained as fallback.
4. Sustainability v1: always-on MATLAB + OS metrics; external tools are enrichers.
5. Legacy policy: archive + redirect (not destructive delete).
6. Sequential commits are mandatory by phase.
