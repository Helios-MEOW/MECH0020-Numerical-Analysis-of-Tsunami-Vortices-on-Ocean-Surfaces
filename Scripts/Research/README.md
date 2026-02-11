# Research Synthesis Pipeline

NotebookLM-style pipeline for local PDF corpus processing and Notion publishing.

## CLI Tools

- `build_manifest.py`
- `extract_assets.py`
- `summarize_papers.py`
- `compose_report.py`
- `publish_notion.py`

## End-to-End Usage

Run from repo root:

```powershell
python Scripts/Research/build_manifest.py \
  --papers-dir "Research Papers" \
  --out-dir "Artifacts/research_report_2026-02-11"

python Scripts/Research/extract_assets.py \
  --manifest "Artifacts/research_report_2026-02-11/manifest_unique.json" \
  --out-dir "Artifacts/research_report_2026-02-11" \
  --ris "Research Papers/MECH0020.ris"

python Scripts/Research/summarize_papers.py \
  --manifest "Artifacts/research_report_2026-02-11/manifest_unique.json" \
  --assets-dir "Artifacts/research_report_2026-02-11" \
  --out-json "Artifacts/research_report_2026-02-11/paper_summaries.json"

python Scripts/Research/compose_report.py \
  --summary-json "Artifacts/research_report_2026-02-11/paper_summaries.json" \
  --output-md "Markdowns/deep-research-report-2026-02-11.md" \
  --images-root "Artifacts/research_report_2026-02-11/papers"

$env:NOTION_API_KEY = "<your-token>"
python Scripts/Research/publish_notion.py \
  --markdown-path "Markdowns/deep-research-report-2026-02-11.md" \
  --parent-page-id "304abae6d98781c9b114c8a8834defd1" \
  --token-env "NOTION_API_KEY" \
  --artifacts-dir "Artifacts/research_report_2026-02-11"
```

## Outputs

- `Artifacts/research_report_2026-02-11/manifest_all.json`
- `Artifacts/research_report_2026-02-11/manifest_unique.json`
- `Artifacts/research_report_2026-02-11/papers/<paper_id>/*`
- `Artifacts/research_report_2026-02-11/paper_summaries.json`
- `Markdowns/deep-research-report-2026-02-11.md`
- `Artifacts/research_report_2026-02-11/notion_publish_log.json` (if publish succeeds)
- `Artifacts/research_report_2026-02-11/notion_page_meta.json` (if publish succeeds)

## Notes

- Deduplication uses SHA-256 file hash.
- Unicode file paths are handled via ASCII staging fallback.
- Figures are filtered to remove likely decorative assets.
- Notion publish requires integration token and page-sharing permissions.
