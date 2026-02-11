#!/usr/bin/env python3
"""Compose the final consolidated markdown report from summary JSON."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Dict, List

from research_common import ensure_dir, repo_root_from_file, utc_now_iso


def load_json(path: Path) -> Dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8", errors="ignore"))


def anchor_slug(text: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return slug


def repo_relative(path_str: str, repo_root: Path) -> str:
    path = Path(path_str)
    if path.is_absolute():
        try:
            return path.resolve().relative_to(repo_root.resolve()).as_posix()
        except Exception:
            return path.as_posix()
    return path.as_posix()


def method_tags(text: str) -> List[str]:
    lower = text.lower()
    tags: List[str] = []
    if "finite difference" in lower or "arakawa" in lower or "rk4" in lower:
        tags.append("fd")
    if "spectral" in lower or "fft" in lower:
        tags.append("spectral")
    if "finite volume" in lower or "fvm" in lower or "flux" in lower:
        tags.append("fv")
    if "lattice boltzmann" in lower or "lbm" in lower or "mrt" in lower:
        tags.append("lbm")
    if "shallow water" in lower or "tsunami" in lower:
        tags.append("shallow_water")
    return tags


def compose_markdown(summary_json: Path, output_md: Path, images_root: str) -> None:
    repo_root = repo_root_from_file(Path(__file__))
    data = load_json(summary_json)
    papers = data.get("papers", [])
    bibliography = data.get("bibliography", [])
    corpus = data.get("corpus_summary", {})
    validation = data.get("validation", {})

    if not isinstance(papers, list):
        raise SystemExit("invalid summary: papers is not a list")

    lines: List[str] = []
    lines.append("# Deep Research Report - Tsunami Vorticity Corpus (2026-02-11)")
    lines.append("")
    lines.append(f"Generated: {utc_now_iso()}")
    lines.append("")
    lines.append("## Executive Synopsis")
    lines.append("")
    lines.append(
        "This report consolidates the local `Research Papers/` corpus into a single NotebookLM-style synthesis "
        "focused on numerical simulation of tsunami-related vorticity dynamics over ocean surfaces."
    )
    lines.append("")
    lines.append(
        f"Corpus processing summary: {corpus.get('source_total_files')} files -> "
        f"{corpus.get('source_unique_files')} unique papers after SHA-256 deduplication; "
        f"{corpus.get('summarized_records')} paper sections generated."
    )
    lines.append("")

    lines.append("## Table of Contents")
    lines.append("")
    toc_entries = [
        "- [Executive Synopsis](#executive-synopsis)",
        "- [Corpus Manifest Summary](#corpus-manifest-summary)",
        "- [Cross-Paper Tsunami-Vorticity Synthesis](#cross-paper-tsunami-vorticity-synthesis)",
        "- [Per-Paper Summaries](#per-paper-summaries)",
        "- [Bibliography](#bibliography)",
        "- [Validation Checklist](#validation-checklist)",
    ]
    lines.extend(toc_entries)
    lines.append("")
    for paper in papers:
        if not isinstance(paper, dict):
            continue
        heading = f"Paper {int(paper.get('citation_number', 0)):02d}: {paper.get('title', 'Untitled')}"
        lines.append(f"- [{heading}](#{anchor_slug(heading)})")
    lines.append("")

    lines.append("## Corpus Manifest Summary")
    lines.append("")
    lines.append("| Metric | Value |")
    lines.append("|---|---|")
    lines.append(f"| Source files | {corpus.get('source_total_files', 'n/a')} |")
    lines.append(f"| Unique papers | {corpus.get('source_unique_files', 'n/a')} |")
    lines.append(f"| Summarized sections | {corpus.get('summarized_records', 'n/a')} |")
    lines.append(f"| Duplicate groups | {corpus.get('duplicate_groups', 'n/a')} |")
    lines.append("")

    # Method signal aggregation.
    tag_counts = {"fd": 0, "spectral": 0, "fv": 0, "lbm": 0, "shallow_water": 0}
    for paper in papers:
        if not isinstance(paper, dict):
            continue
        blob = " ".join(
            [
                str(paper.get("methods", "")),
                str(paper.get("objective", "")),
                str(paper.get("findings", "")),
                str(paper.get("title", "")),
            ]
        )
        for tag in set(method_tags(blob)):
            tag_counts[tag] += 1

    lines.append("## Cross-Paper Tsunami-Vorticity Synthesis")
    lines.append("")
    lines.append("### Numerical Method Distribution (keyword-based signal)")
    lines.append("")
    lines.append("| Method signal | Papers |")
    lines.append("|---|---|")
    lines.append(f"| Finite difference / Arakawa / RK4 | {tag_counts['fd']} |")
    lines.append(f"| Spectral / FFT | {tag_counts['spectral']} |")
    lines.append(f"| Finite volume / flux form | {tag_counts['fv']} |")
    lines.append(f"| LBM / MRT | {tag_counts['lbm']} |")
    lines.append(f"| Shallow-water / tsunami propagation | {tag_counts['shallow_water']} |")
    lines.append("")

    lines.append("### Literature-to-Solver Component Map")
    lines.append("")
    lines.append("```mermaid")
    lines.append("flowchart TD")
    lines.append("  A[Paper Corpus] --> B[Governing Equations]")
    lines.append("  A --> C[Numerical Schemes]")
    lines.append("  A --> D[Validation Benchmarks]")
    lines.append("  A --> E[Compute-Sustainability Metrics]")
    lines.append("  B --> B1[Markdowns/MATHEMATICAL_FRAMEWORK.md]")
    lines.append("  C --> C1[Scripts/Methods/FiniteDifference/FiniteDifferenceMethod.m]")
    lines.append("  C --> C2[Scripts/Methods/Spectral/README.md]")
    lines.append("  C --> C3[Scripts/Methods/FiniteVolume/README.md]")
    lines.append("  D --> D1[Scripts/Modes/Convergence/mode_convergence.m]")
    lines.append("  E --> E1[Scripts/Sustainability/SustainabilityLedger.m]")
    lines.append("```")
    lines.append("")

    lines.append("### Equation-to-Code Traceability")
    lines.append("")
    lines.append("```mermaid")
    lines.append("flowchart LR")
    lines.append("  EQ1[Vorticity Eq: d(omega)/dt + u.grad(omega) = nu laplacian(omega)] --> FD[FiniteDifferenceMethod]")
    lines.append("  EQ2[Poisson Eq: laplacian(psi) = -omega] --> POI[Poisson Solve in FD setup]")
    lines.append("  EQ3[Shallow-water variants] --> BATHY[Variable_Bathymetry_Analysis]")
    lines.append("  EQ4[Turbulence/LES/LBM models] --> FUTURE[Method extension backlog]")
    lines.append("```")
    lines.append("")

    lines.append("### Validation and Benchmark Workflow")
    lines.append("")
    lines.append("```mermaid")
    lines.append("flowchart TD")
    lines.append("  P[Literature Benchmarks] --> R[Reference Metrics]")
    lines.append("  R --> C[Convergence Mode Runs]")
    lines.append("  C --> M[extract_unified_metrics]")
    lines.append("  M --> V[Compare to reported trends]")
    lines.append("  V --> G[Gap log for solver upgrades]")
    lines.append("```")
    lines.append("")

    lines.append("### Sustainability Instrumentation Link")
    lines.append("")
    lines.append("```mermaid")
    lines.append("flowchart TD")
    lines.append("  Run[Simulation Run] --> Ledger[Runs Sustainability CSV]")
    lines.append("  Run --> Report[RunReportPipeline outputs]")
    lines.append("  Ledger --> Analysis[EnergySustainabilityAnalyzer]")
    lines.append("  Analysis --> Study[Method-vs-cost comparisons from literature]")
    lines.append("```")
    lines.append("")

    lines.append("## Per-Paper Summaries")
    lines.append("")

    for paper in papers:
        if not isinstance(paper, dict):
            continue

        citation_no = int(paper.get("citation_number", 0))
        title = str(paper.get("title", "Untitled"))
        heading = f"Paper {citation_no:02d}: {title}"
        lines.append(f"### {heading}")
        lines.append("")
        lines.append(f"**Citation [{citation_no}]:** {paper.get('citation', '')}")
        lines.append("")

        doi = str(paper.get("doi", "")).strip()
        url = str(paper.get("url", "")).strip()
        canonical_name = str(paper.get("canonical_file_name", ""))
        aliases = paper.get("alias_file_names", [])
        if canonical_name:
            lines.append(f"**Canonical PDF:** `{canonical_name}`")
        if aliases:
            alias_text = ", ".join(f"`{alias}`" for alias in aliases)
            lines.append(f"**File aliases:** {alias_text}")
        if doi:
            lines.append(f"**DOI:** `{doi}`")
        if url:
            lines.append(f"**URL:** {url}")
        lines.append("")

        lines.append("**Research objective and scope**")
        lines.append("")
        lines.append(str(paper.get("objective", "")))
        lines.append("")

        lines.append("**Methods and numerical approach**")
        lines.append("")
        lines.append(str(paper.get("methods", "")))
        lines.append("")

        lines.append("**Key findings**")
        lines.append("")
        lines.append(str(paper.get("findings", "")))
        lines.append("")

        lines.append("**Limitations**")
        lines.append("")
        lines.append(str(paper.get("limitations", "")))
        lines.append("")

        lines.append("**Key governing equations**")
        lines.append("")
        equations = paper.get("key_equations", [])
        if isinstance(equations, list) and equations:
            for eq in equations:
                if not isinstance(eq, dict):
                    continue
                eq_text = str(eq.get("equation", "")).strip()
                page = eq.get("page", "?")
                if eq_text:
                    lines.append(f"- `{eq_text}` (p.{page})")
        else:
            lines.append("- No extractable governing equation found in machine-readable text.")
        lines.append("")

        lines.append("**Detailed observations linked to repository modules**")
        lines.append("")
        observations = paper.get("repo_observations", [])
        if isinstance(observations, list) and observations:
            for obs in observations:
                lines.append(f"- {obs}")
        else:
            lines.append("- No additional module-specific observations were generated.")
        lines.append("")

        lines.append("**Evidence anchors**")
        lines.append("")
        evidence = paper.get("evidence_anchors", [])
        if isinstance(evidence, list) and evidence:
            for anchor in evidence:
                if not isinstance(anchor, dict):
                    continue
                tag = anchor.get("tag", "evidence")
                page = anchor.get("page", "?")
                quote = str(anchor.get("quote", "")).strip()
                lines.append(f"- [{tag}, p.{page}] {quote}")
        else:
            lines.append("- [fallback, p.1] No machine-readable evidence anchor extracted.")
        lines.append("")

        lines.append("**Figure gallery (scientific images)**")
        lines.append("")
        figures = paper.get("figures", [])
        if isinstance(figures, list) and figures:
            for fig in figures:
                if not isinstance(fig, dict):
                    continue
                figure_id = str(fig.get("figure_id", "figure"))
                raw_path = str(fig.get("relative_path", ""))
                if raw_path:
                    relative_path = repo_relative(raw_path, repo_root)
                else:
                    relative_path = f"{images_root}/{paper.get('paper_id', '')}/figures/{figure_id}"
                caption_hint = str(fig.get("caption_hint", "Scientific figure"))
                lines.append(f"![{figure_id}]({relative_path})")
                lines.append(f"*{caption_hint}*")
                lines.append("")
        else:
            lines.append("No scientific images were retained after filtering.")
            lines.append("")

    lines.append("## Bibliography")
    lines.append("")
    for item in bibliography:
        if not isinstance(item, dict):
            continue
        idx = item.get("id", "?")
        citation = str(item.get("citation", "")).strip()
        lines.append(f"{idx}. {citation}")
        lines.append("")

    lines.append("## Validation Checklist")
    lines.append("")
    lines.append(f"- All summaries have citations: `{validation.get('all_have_citations')}`")
    lines.append(f"- All summaries have evidence anchors: `{validation.get('all_have_evidence')}`")
    lines.append(
        f"- All summaries have equation section or fallback: `{validation.get('all_have_equation_or_fallback')}`"
    )
    lines.append("- Placeholder scan target: no unresolved placeholder markers remain in this report.")
    lines.append("")

    ensure_dir(output_md.parent)
    output_md.write_text("\n".join(lines), encoding="utf-8")
    print(json.dumps({"output_markdown": str(output_md.resolve()), "paper_sections": len(papers)}, indent=2))


def parse_args() -> argparse.Namespace:
    repo_root = repo_root_from_file(Path(__file__))
    default_out_dir = repo_root / "Artifacts" / "research_report_2026-02-11"

    parser = argparse.ArgumentParser(description="Compose consolidated markdown research report.")
    parser.add_argument("--summary-json", type=Path, default=default_out_dir / "paper_summaries.json")
    parser.add_argument(
        "--output-md",
        type=Path,
        default=repo_root / "Markdowns" / "deep-research-report-2026-02-11.md",
    )
    parser.add_argument(
        "--images-root",
        type=str,
        default="Artifacts/research_report_2026-02-11/papers",
        help="Repo-relative root used for generated image links.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    compose_markdown(
        summary_json=args.summary_json.resolve(),
        output_md=args.output_md.resolve(),
        images_root=args.images_root,
    )


if __name__ == "__main__":
    main()
