#!/usr/bin/env python3
"""Generate NotebookLM-style per-paper summaries from extracted assets."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Dict, List, Sequence, Tuple

from research_common import (
    clean_whitespace,
    ensure_dir,
    json_dump,
    repo_root_from_file,
    sentence_tokenize,
    split_pages_from_pdftotext,
    utc_now_iso,
)

ABSTRACT_REGEX = re.compile(
    r"(?is)\babstract\b[:\s\-]*(.+?)(?:\n\s*(?:keywords?|1\.?\s+introduction|introduction)\b|$)"
)


def load_json(path: Path) -> Dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8", errors="ignore"))


def load_pages(text_path: Path) -> List[str]:
    if not text_path.exists():
        return []
    text = text_path.read_text(encoding="utf-8", errors="ignore")
    return split_pages_from_pdftotext(text)


def extract_abstract_snippet(pages: List[str]) -> Tuple[str, int]:
    if not pages:
        return "", 1
    first_three = "\n".join(pages[:3])
    match = ABSTRACT_REGEX.search(first_three)
    if match:
        snippet = clean_whitespace(match.group(1))
        return snippet[:2400], 1

    fallback = clean_whitespace("\n".join(pages[:2]))
    return fallback[:2000], 1


def collect_sentences_with_pages(pages: List[str], page_limit: int = 8) -> List[Dict[str, object]]:
    collected: List[Dict[str, object]] = []
    for page_no, page_text in enumerate(pages[:page_limit], start=1):
        raw_lines = [clean_whitespace(line) for line in page_text.splitlines()]
        raw_lines = [line for line in raw_lines if len(line) >= 20]
        for line in raw_lines:
            for sent in sentence_tokenize(line):
                if len(sent) < 25:
                    continue
                if len(sent) > 320:
                    sent = sent[:320]
                collected.append({"page": page_no, "text": sent})
    return collected


def pick_sentences(
    sentences: Sequence[Dict[str, object]],
    keywords: Sequence[str],
    limit: int,
) -> List[Dict[str, object]]:
    chosen: List[Dict[str, object]] = []
    seen = set()

    lower_keywords = [kw.lower() for kw in keywords]

    for item in sentences:
        text = str(item["text"])
        lower = text.lower()
        if any(keyword in lower for keyword in lower_keywords):
            norm = re.sub(r"\s+", " ", lower)
            if norm in seen:
                continue
            chosen.append(item)
            seen.add(norm)
            if len(chosen) >= limit:
                return chosen

    for item in sentences:
        text = str(item["text"])
        norm = re.sub(r"\s+", " ", text.lower())
        if norm in seen:
            continue
        chosen.append(item)
        seen.add(norm)
        if len(chosen) >= limit:
            break

    return chosen


def format_paragraph_from_sentences(items: List[Dict[str, object]], fallback: str) -> str:
    if not items:
        return fallback
    return " ".join(str(item["text"]) for item in items)


def build_repo_observations(full_text: str) -> List[str]:
    lower = full_text.lower()
    observations: List[str] = []

    observations.append(
        "This paper links to the vorticity-streamfunction implementation documented in `Markdowns/MATHEMATICAL_FRAMEWORK.md` and `Scripts/Methods/FiniteDifference/README.md`."
    )

    if any(token in lower for token in ["arakawa", "finite difference", "rk4", "jacobian"]):
        observations.append(
            "Its numerical treatment can be mapped to the active FD path in `Scripts/Methods/FiniteDifference/FiniteDifferenceMethod.m` and runtime dispatch in `Scripts/Drivers/Tsunami_Vorticity_Emulator.m`."
        )

    if any(token in lower for token in ["spectral", "fft", "fourier"]):
        observations.append(
            "It informs the experimental spectral branch under `Scripts/Methods/Spectral/README.md`, which is currently not fully wired in dispatcher modes."
        )

    if any(token in lower for token in ["finite volume", "fvm", "flux"]):
        observations.append(
            "It provides method-level rationale for the finite-volume roadmap in `Scripts/Methods/FiniteVolume/README.md`."
        )

    if any(token in lower for token in ["validation", "benchmark", "convergence", "error"]):
        observations.append(
            "Its benchmarking ideas are directly relevant to convergence workflows in `Scripts/Modes/Convergence/mode_convergence.m` and `Scripts/Modes/Convergence/run_adaptive_convergence.m`."
        )

    if any(token in lower for token in ["bathymetry", "topography", "shallow water", "boundary layer", "tsunami"]):
        observations.append(
            "Its physical assumptions should be cross-checked against variable-bathymetry handling in `Scripts/Modes/Variable_Bathymetry_Analysis.m` and planned mode/method unification."
        )

    if any(token in lower for token in ["energy", "sustainability", "power", "computational cost", "gpu"]):
        observations.append(
            "Its compute-performance implications connect to sustainability instrumentation in `Scripts/Sustainability/SustainabilityLedger.m` and `Scripts/Sustainability/EnergySustainabilityAnalyzer.m`."
        )

    if any(token in lower for token in ["machine learning", "data-driven", "surrogate", "ai"]):
        observations.append(
            "Its modeling direction can be compared with the ML roadmap in `Markdowns/MACHINE_LEARNING_VORTICITY_ABSORPTION.md`."
        )

    return observations[:6]


def extract_findings(sentences: Sequence[Dict[str, object]], limit: int = 3) -> List[Dict[str, object]]:
    return pick_sentences(
        sentences,
        keywords=["result", "show", "found", "demonstrat", "agree", "accuracy", "performance"],
        limit=limit,
    )


def extract_methods(sentences: Sequence[Dict[str, object]], limit: int = 3) -> List[Dict[str, object]]:
    return pick_sentences(
        sentences,
        keywords=[
            "method",
            "numerical",
            "simulation",
            "finite",
            "spectral",
            "lattice",
            "solver",
            "scheme",
            "equation",
        ],
        limit=limit,
    )


def extract_objective(sentences: Sequence[Dict[str, object]], limit: int = 2) -> List[Dict[str, object]]:
    return pick_sentences(
        sentences,
        keywords=["this paper", "this study", "we present", "we investigate", "we propose", "aim", "objective"],
        limit=limit,
    )


def extract_limitations(sentences: Sequence[Dict[str, object]], limit: int = 2) -> List[Dict[str, object]]:
    return pick_sentences(
        sentences,
        keywords=["limitation", "future", "however", "assume", "restricted", "challenge", "uncertain"],
        limit=limit,
    )


def build_evidence_anchors(
    objective: Sequence[Dict[str, object]],
    methods: Sequence[Dict[str, object]],
    findings: Sequence[Dict[str, object]],
    limitations: Sequence[Dict[str, object]],
    equations: Sequence[Dict[str, object]],
) -> List[Dict[str, object]]:
    anchors: List[Dict[str, object]] = []

    def add_items(items: Sequence[Dict[str, object]], tag: str, key_name: str = "text") -> None:
        for item in items:
            quote = clean_whitespace(str(item.get(key_name, "")))
            if not quote:
                continue
            anchors.append(
                {
                    "tag": tag,
                    "page": int(item.get("page", 1)),
                    "quote": quote[:280],
                }
            )

    add_items(objective, "objective")
    add_items(methods, "methods")
    add_items(findings, "findings")
    add_items(limitations, "limitations")
    add_items(equations, "equation", key_name="equation")

    unique = []
    seen = set()
    for anchor in anchors:
        key = (anchor["tag"], anchor["page"], anchor["quote"].lower())
        if key in seen:
            continue
        seen.add(key)
        unique.append(anchor)
    return unique[:14]


def summarize_papers(manifest_path: Path, assets_dir: Path, out_json: Path) -> None:
    manifest = load_json(manifest_path)
    papers = manifest.get("papers", [])
    if not isinstance(papers, list):
        raise SystemExit("invalid manifest format")

    summaries: List[Dict[str, object]] = []
    bibliography: List[Dict[str, object]] = []

    for citation_number, paper in enumerate(papers, start=1):
        if not isinstance(paper, dict):
            continue

        paper_id = str(paper["paper_id"])
        paper_dir = assets_dir / "papers" / paper_id
        metadata_path = paper_dir / "metadata.json"
        text_path = paper_dir / "text.txt"
        eq_path = paper_dir / "equation_candidates.json"
        fig_path = paper_dir / "figures_index.json"

        if not metadata_path.exists():
            print(f"[warn] missing metadata for {paper_id}; skipping")
            continue

        metadata = load_json(metadata_path)
        pages = load_pages(text_path)
        equations = load_json(eq_path) if eq_path.exists() else []
        figures_index = load_json(fig_path) if fig_path.exists() else {"figures": []}

        abstract_text, abstract_page = extract_abstract_snippet(pages)
        sentence_pool = collect_sentences_with_pages(pages, page_limit=10)

        objective_sentences = extract_objective(sentence_pool, limit=2)
        methods_sentences = extract_methods(sentence_pool, limit=3)
        findings_sentences = extract_findings(sentence_pool, limit=3)
        limitation_sentences = extract_limitations(sentence_pool, limit=2)

        objective_text = format_paragraph_from_sentences(
            objective_sentences,
            fallback="Automated extraction could not isolate a clear objective sentence; see evidence anchors for source excerpts.",
        )
        methods_text = format_paragraph_from_sentences(
            methods_sentences,
            fallback="Method-specific language was sparse in extracted text; this summary relies on metadata and equation snippets.",
        )
        findings_text = format_paragraph_from_sentences(
            findings_sentences,
            fallback="Clear result statements were not confidently extracted from text; conclusions should be read directly in the source PDF.",
        )
        limitations_text = format_paragraph_from_sentences(
            limitation_sentences,
            fallback="Explicit limitations were not clearly stated in extracted text; treat this as an extraction-confidence caveat.",
        )

        key_equations = equations[:5] if isinstance(equations, list) else []
        if not key_equations:
            key_equations = [
                {
                    "equation": "No extractable governing equation found in machine-readable text.",
                    "page": 1,
                    "score": 0,
                }
            ]

        figures = figures_index.get("figures", []) if isinstance(figures_index, dict) else []

        evidence = build_evidence_anchors(
            objective_sentences,
            methods_sentences,
            findings_sentences,
            limitation_sentences,
            key_equations,
        )
        if not evidence:
            evidence = [
                {
                    "tag": "fallback",
                    "page": abstract_page,
                    "quote": abstract_text[:280] if abstract_text else "No evidence text extracted.",
                }
            ]

        full_text_for_obs = "\n".join(pages[:8])
        repo_observations = build_repo_observations(full_text_for_obs)

        title = str(metadata.get("title") or paper.get("canonical_file_name") or paper_id)
        citation = str(metadata.get("vancouver_citation") or title)
        doi = str(metadata.get("doi") or "")
        url = str(metadata.get("url") or "")

        summary_record = {
            "paper_id": paper_id,
            "citation_number": citation_number,
            "title": title,
            "canonical_file_name": paper.get("canonical_file_name"),
            "alias_file_names": paper.get("alias_file_names", []),
            "objective": objective_text,
            "methods": methods_text,
            "findings": findings_text,
            "limitations": limitations_text,
            "abstract_excerpt": abstract_text,
            "key_equations": key_equations,
            "repo_observations": repo_observations,
            "evidence_anchors": evidence,
            "figures": figures,
            "citation": citation,
            "doi": doi,
            "url": url,
            "year": metadata.get("year", ""),
            "journal": metadata.get("journal", ""),
            "authors": metadata.get("authors", []),
            "text_quality": metadata.get("extraction", {}).get("text_quality", {}).get("quality", "unknown"),
            "figure_count": len(figures),
            "equation_count": len(key_equations),
        }

        summaries.append(summary_record)
        bibliography.append(
            {
                "id": citation_number,
                "paper_id": paper_id,
                "title": title,
                "citation": citation,
                "doi": doi,
                "url": url,
            }
        )

        print(f"[ok] summarized {paper_id} | figs={len(figures)} | eq={len(key_equations)}")

    output = {
        "generated_at_utc": utc_now_iso(),
        "manifest_path": str(manifest_path.resolve()),
        "assets_dir": str(assets_dir.resolve()),
        "corpus_summary": {
            "source_total_files": manifest.get("source_total_files"),
            "source_unique_files": manifest.get("source_unique_files"),
            "summarized_records": len(summaries),
            "duplicate_groups": sum(1 for p in papers if isinstance(p, dict) and int(p.get("duplicate_count", 0)) > 0),
        },
        "papers": summaries,
        "bibliography": bibliography,
        "validation": {
            "all_have_citations": all(bool(item.get("citation")) for item in summaries),
            "all_have_evidence": all(len(item.get("evidence_anchors", [])) > 0 for item in summaries),
            "all_have_equation_or_fallback": all(len(item.get("key_equations", [])) > 0 for item in summaries),
        },
    }

    json_dump(out_json, output)
    print(json.dumps({"summary_json": str(out_json.resolve()), "papers": len(summaries)}, indent=2))


def parse_args() -> argparse.Namespace:
    repo_root = repo_root_from_file(Path(__file__))
    default_out_dir = repo_root / "Artifacts" / "research_report_2026-02-11"

    parser = argparse.ArgumentParser(description="Summarize extracted paper assets into structured JSON.")
    parser.add_argument("--manifest", type=Path, default=default_out_dir / "manifest_unique.json")
    parser.add_argument("--assets-dir", type=Path, default=default_out_dir)
    parser.add_argument("--out-json", type=Path, default=default_out_dir / "paper_summaries.json")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    summarize_papers(
        manifest_path=args.manifest.resolve(),
        assets_dir=args.assets_dir.resolve(),
        out_json=args.out_json.resolve(),
    )


if __name__ == "__main__":
    main()
