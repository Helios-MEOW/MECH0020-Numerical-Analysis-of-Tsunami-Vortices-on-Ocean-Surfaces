#!/usr/bin/env python3
"""Extract text, metadata, equations, and figures for each unique paper."""

from __future__ import annotations

import argparse
import hashlib
import json
import mimetypes
import re
import shutil
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from research_common import (
    build_ris_indexes,
    clean_whitespace,
    detect_doi,
    ensure_dir,
    extract_title_from_page,
    find_ris_match,
    json_dump,
    parse_ris_file,
    parse_size_token,
    relative_repo_path,
    repo_root_from_file,
    run_command,
    sentence_tokenize,
    split_pages_from_pdftotext,
    to_vancouver_citation,
    utc_now_iso,
)

EQUATION_SYMBOLS = re.compile(r"[\u2202\u2207\u0394\u03c9\u03c8\u03bd\u03b7\u03a3]")
YEAR_REGEX = re.compile(r"\b(19|20)\d{2}\b")


def load_manifest(path: Path) -> Dict[str, object]:
    return json.loads(path.read_text(encoding="utf-8"))


def choose_ascii_stage_name(paper_id: str) -> str:
    return f"{paper_id}.pdf"


def try_extract_text(pdf_path: Path, text_out: Path) -> Tuple[bool, str]:
    cmd = ["pdftotext", str(pdf_path), str(text_out)]
    result = run_command(cmd, timeout=600)
    if result.code == 0 and text_out.exists():
        return True, "direct"
    return False, result.stderr.strip() or "pdftotext failed"


def extract_full_text(
    source_pdf: Path,
    staging_pdf: Path,
    text_out: Path,
    prefer_staging: bool,
) -> Tuple[bool, str, Path]:
    candidates = [staging_pdf, source_pdf] if prefer_staging else [source_pdf, staging_pdf]

    for candidate in candidates:
        if candidate == staging_pdf:
            ensure_dir(staging_pdf.parent)
            shutil.copy2(source_pdf, staging_pdf)
        ok, note = try_extract_text(candidate, text_out)
        if ok:
            return True, note if candidate == source_pdf else "staged_path", candidate

    return False, "failed on direct and staged path", source_pdf


def parse_pdfimages_list(output: str) -> List[Dict[str, object]]:
    rows: List[Dict[str, object]] = []
    for line in output.splitlines():
        line = line.strip()
        if not line or line.startswith("page") or line.startswith("-"):
            continue
        tokens = line.split()
        if len(tokens) < 16:
            continue
        try:
            row = {
                "page": int(tokens[-16]),
                "num": int(tokens[-15]),
                "type": tokens[-14],
                "width": int(tokens[-13]),
                "height": int(tokens[-12]),
                "color": tokens[-11],
                "comp": tokens[-10],
                "bpc": tokens[-9],
                "enc": tokens[-8],
                "interp": tokens[-7],
                "object_id": tokens[-6],
                "object_gen": tokens[-5],
                "x_ppi": tokens[-4],
                "y_ppi": tokens[-3],
                "size_token": tokens[-2],
                "ratio": tokens[-1],
            }
            rows.append(row)
        except Exception:
            continue
    return rows


def image_index_from_filename(path: Path) -> Optional[int]:
    match = re.search(r"-(\d+)\.[A-Za-z0-9]+$", path.name)
    if not match:
        return None
    return int(match.group(1))


def hash_file(path: Path) -> str:
    digest = hashlib.sha1()
    with path.open("rb") as handle:
        while True:
            block = handle.read(1024 * 1024)
            if not block:
                break
            digest.update(block)
    return digest.hexdigest()


def should_keep_image(row: Dict[str, object], file_size: int) -> Tuple[bool, str]:
    width = int(row.get("width", 0))
    height = int(row.get("height", 0))
    area = width * height
    image_type = str(row.get("type", "")).lower()
    page = int(row.get("page", 0))

    if image_type in {"mask", "smask", "stencil"}:
        return False, "mask_or_stencil"
    if width < 160 or height < 160:
        return False, "too_small_dimensions"
    if area < 60000:
        return False, "too_small_area"
    if min(width, height) == 0:
        return False, "invalid_dimensions"

    aspect = max(width, height) / float(min(width, height))
    if aspect > 6.0:
        return False, "extreme_aspect_ratio"
    if file_size < 8192:
        return False, "too_small_file"

    # Typical journal logos/icons are usually small and on first pages.
    if page <= 2 and width <= 420 and height <= 420 and file_size < 50000:
        return False, "likely_decorative_frontmatter"

    return True, "kept"


def extract_figures(
    working_pdf: Path,
    figures_dir: Path,
    raw_dir: Path,
    pages_count: int,
) -> Dict[str, object]:
    ensure_dir(figures_dir)
    ensure_dir(raw_dir)

    list_result = run_command(["pdfimages", "-list", str(working_pdf)], timeout=600)
    rows = parse_pdfimages_list(list_result.stdout) if list_result.code == 0 else []

    prefix = raw_dir / "img"
    extract_result = run_command(["pdfimages", "-png", str(working_pdf), str(prefix)], timeout=1200)

    extracted_files = sorted(raw_dir.glob("img-*.png"), key=lambda p: image_index_from_filename(p) or -1)
    file_by_index: Dict[int, Path] = {}
    for file_path in extracted_files:
        idx = image_index_from_filename(file_path)
        if idx is None:
            continue
        file_by_index[idx] = file_path

    kept: List[Dict[str, object]] = []
    rejected: List[Dict[str, object]] = []
    seen_hashes = set()

    for row in rows:
        idx = int(row["num"])
        image_path = file_by_index.get(idx)
        if image_path is None or not image_path.exists():
            rejected.append({"num": idx, "reason": "missing_output_file"})
            continue

        file_size = image_path.stat().st_size
        keep, reason = should_keep_image(row, file_size)
        if not keep:
            rejected.append({"num": idx, "reason": reason})
            image_path.unlink(missing_ok=True)
            continue

        img_hash = hash_file(image_path)
        if img_hash in seen_hashes:
            rejected.append({"num": idx, "reason": "duplicate_hash"})
            image_path.unlink(missing_ok=True)
            continue

        seen_hashes.add(img_hash)
        ext = image_path.suffix.lower()
        out_name = f"fig_{len(kept) + 1:04d}{ext}"
        out_path = figures_dir / out_name
        shutil.move(str(image_path), str(out_path))

        kept.append(
            {
                "figure_id": out_name,
                "source": "embedded_image",
                "page": row.get("page"),
                "width": row.get("width"),
                "height": row.get("height"),
                "size_bytes": file_size,
                "relative_path": out_path.as_posix(),
                "caption_hint": f"Embedded figure from page {row.get('page')}",
            }
        )

    # Fallback when no scientific embedded images survived filtering.
    fallback_pages = min(12, max(0, pages_count))
    fallback_used = False
    if len(kept) == 0 and fallback_pages > 0:
        fallback_used = True
        render_prefix = raw_dir / "page"
        render_result = run_command(
            [
                "pdftoppm",
                "-png",
                "-f",
                "1",
                "-l",
                str(fallback_pages),
                str(working_pdf),
                str(render_prefix),
            ],
            timeout=1200,
        )
        if render_result.code == 0:
            rendered = sorted(raw_dir.glob("page-*.png"), key=lambda p: p.name)
            for idx, page_img in enumerate(rendered, start=1):
                out_name = f"render_{idx:04d}.png"
                out_path = figures_dir / out_name
                shutil.move(str(page_img), str(out_path))
                kept.append(
                    {
                        "figure_id": out_name,
                        "source": "page_render",
                        "page": idx,
                        "width": None,
                        "height": None,
                        "size_bytes": out_path.stat().st_size,
                        "relative_path": out_path.as_posix(),
                        "caption_hint": f"Fallback rendered page {idx}",
                    }
                )

    # Cleanup raw extraction leftovers.
    if raw_dir.exists():
        shutil.rmtree(raw_dir, ignore_errors=True)

    return {
        "pdfimages_rows": len(rows),
        "pdfimages_exit_code": list_result.code,
        "pdfimages_extract_exit_code": extract_result.code,
        "kept_count": len(kept),
        "rejected_count": len(rejected),
        "fallback_used": fallback_used,
        "figures": kept,
        "rejections": rejected[:200],
    }


def extract_equation_candidates(pages: List[str], limit: int = 12) -> List[Dict[str, object]]:
    candidates: List[Dict[str, object]] = []
    seen = set()

    for page_idx, page_text in enumerate(pages, start=1):
        for raw_line in page_text.splitlines():
            line = clean_whitespace(raw_line)
            if not line or "=" not in line:
                continue
            if len(line) < 8 or len(line) > 220:
                continue

            score = 0
            lower = line.lower()
            if any(token in lower for token in ["d/dt", "partial", "nabla", "laplac", "jacobian", "cfl", "reynolds"]):
                score += 2
            if any(token in lower for token in ["omega", "psi", "eta", "nu", "u", "v", "h"]):
                score += 1
            if re.search(r"\(\d+(\.\d+)?\)$", line):
                score += 2
            if EQUATION_SYMBOLS.search(line):
                score += 2
            if re.search(r"[\+\-\*/]", line):
                score += 1

            if score < 2:
                continue

            normalized = re.sub(r"\s+", "", line.lower())
            if normalized in seen:
                continue
            seen.add(normalized)

            candidates.append({"equation": line, "page": page_idx, "score": score})

    candidates.sort(key=lambda item: (-int(item["score"]), int(item["page"])))
    return candidates[:limit]


def build_metadata(
    paper: Dict[str, object],
    pages: List[str],
    ris_by_doi: Dict[str, Dict[str, object]],
    ris_by_title: Dict[str, Dict[str, object]],
    repo_root: Path,
) -> Dict[str, object]:
    first_pages = "\n".join(pages[:3])
    first_page = pages[0] if pages else ""

    doi = detect_doi(first_pages)
    title_candidate = extract_title_from_page(first_page)

    ris_match = find_ris_match(doi, title_candidate, ris_by_doi, ris_by_title)

    year = ""
    year_match = YEAR_REGEX.search(first_pages)
    if year_match:
        year = year_match.group(0)

    metadata: Dict[str, object] = {
        "paper_id": paper["paper_id"],
        "canonical_file_name": paper["canonical_file_name"],
        "canonical_relative_path": paper["canonical_relative_path"],
        "alias_file_names": paper.get("alias_file_names", []),
        "title": title_candidate,
        "doi": doi or "",
        "journal": "",
        "year": year,
        "authors": [],
        "url": "",
        "ris_matched": False,
        "extract_title_source": "first_page_heuristic" if title_candidate else "unknown",
        "extract_doi_source": "first_3_pages" if doi else "unknown",
        "repo_relative_pdf": relative_repo_path(Path(str(paper["canonical_absolute_path"])), repo_root),
    }

    if ris_match:
        metadata["ris_matched"] = True
        if ris_match.get("title"):
            metadata["title"] = ris_match["title"]
        if ris_match.get("doi"):
            metadata["doi"] = ris_match["doi"]
        if ris_match.get("journal"):
            metadata["journal"] = ris_match["journal"]
        if ris_match.get("year"):
            metadata["year"] = str(ris_match["year"])
        if ris_match.get("authors"):
            metadata["authors"] = ris_match["authors"]
        if ris_match.get("url"):
            metadata["url"] = ris_match["url"]

    if not metadata["title"]:
        metadata["title"] = Path(str(paper["canonical_file_name"])).stem

    metadata["vancouver_citation"] = to_vancouver_citation(
        {
            "authors": metadata.get("authors", []),
            "title": metadata.get("title", ""),
            "journal": metadata.get("journal", ""),
            "year": metadata.get("year", ""),
            "doi": metadata.get("doi", ""),
            "url": metadata.get("url", ""),
        },
        fallback_title=str(metadata["title"]),
        fallback_url=str(metadata.get("url", "")),
    )

    return metadata


def build_text_quality_summary(full_text: str, pages: List[str]) -> Dict[str, object]:
    text_chars = len(full_text)
    text_words = len(full_text.split())
    nonempty_pages = sum(1 for page in pages if page.strip())

    quality = "good"
    if text_chars < 3000:
        quality = "low"
    if text_chars < 300:
        quality = "very_low"

    return {
        "char_count": text_chars,
        "word_count": text_words,
        "page_count_from_text": len(pages),
        "nonempty_pages": nonempty_pages,
        "quality": quality,
    }


def extract_assets(
    manifest_path: Path,
    out_dir: Path,
    ris_path: Path,
    force: bool,
) -> None:
    repo_root = repo_root_from_file(Path(__file__))
    manifest = load_manifest(manifest_path)
    papers = manifest.get("papers", [])
    if not isinstance(papers, list):
        raise SystemExit("invalid manifest: missing papers list")

    ris_entries = parse_ris_file(ris_path)
    ris_by_doi, ris_by_title = build_ris_indexes(ris_entries)

    papers_root = ensure_dir(out_dir / "papers")
    staging_root = ensure_dir(out_dir / "staging")

    extraction_rows: List[Dict[str, object]] = []

    for paper in papers:
        if not isinstance(paper, dict):
            continue

        paper_id = str(paper["paper_id"])
        paper_dir = ensure_dir(papers_root / paper_id)
        figures_dir = ensure_dir(paper_dir / "figures")
        raw_fig_dir = paper_dir / "_raw_figures"

        text_path = paper_dir / "text.txt"
        metadata_path = paper_dir / "metadata.json"
        eq_path = paper_dir / "equation_candidates.json"
        fig_index_path = paper_dir / "figures_index.json"

        if metadata_path.exists() and not force:
            print(f"[skip] {paper_id}: metadata exists (use --force to regenerate)")
            extraction_rows.append(
                {
                    "paper_id": paper_id,
                    "status": "skipped",
                    "metadata_path": str(metadata_path.resolve()),
                }
            )
            continue

        canonical_pdf = Path(str(paper["canonical_absolute_path"]))
        stage_pdf = staging_root / choose_ascii_stage_name(paper_id)
        prefer_staging = str(paper.get("extractability_status", "")).lower() == "requires_staging"

        # Reset previous outputs when forcing regeneration.
        if force and paper_dir.exists():
            shutil.rmtree(paper_dir, ignore_errors=True)
            paper_dir = ensure_dir(papers_root / paper_id)
            figures_dir = ensure_dir(paper_dir / "figures")
            raw_fig_dir = paper_dir / "_raw_figures"

        ok_text, text_mode, working_pdf = extract_full_text(canonical_pdf, stage_pdf, text_path, prefer_staging)
        full_text = ""
        pages: List[str] = []
        if ok_text and text_path.exists():
            full_text = text_path.read_text(encoding="utf-8", errors="ignore")
            pages = split_pages_from_pdftotext(full_text)

        metadata = build_metadata(paper, pages, ris_by_doi, ris_by_title, repo_root)
        text_quality = build_text_quality_summary(full_text, pages)

        equation_candidates = extract_equation_candidates(pages, limit=12)

        pages_count = int(paper.get("pages") or len(pages) or 0)
        figure_summary = extract_figures(working_pdf, figures_dir, raw_fig_dir, pages_count)

        metadata["extraction"] = {
            "processed_at_utc": utc_now_iso(),
            "text_extracted": ok_text,
            "text_mode": text_mode,
            "working_pdf_path": str(working_pdf),
            "text_quality": text_quality,
            "equation_candidates": len(equation_candidates),
            "figure_count": int(figure_summary["kept_count"]),
            "figure_fallback_used": bool(figure_summary["fallback_used"]),
            "pdf_page_count_declared": paper.get("pages"),
        }

        # Save files.
        json_dump(metadata_path, metadata)
        json_dump(eq_path, equation_candidates)
        json_dump(fig_index_path, figure_summary)

        page_meta = {
            "page_count": len(pages),
            "nonempty_pages": sum(1 for p in pages if p.strip()),
            "first_page_preview": clean_whitespace(pages[0])[:400] if pages else "",
            "first_sentences": sentence_tokenize("\n".join(pages[:2]))[:5],
        }
        json_dump(paper_dir / "pages_meta.json", page_meta)

        extraction_rows.append(
            {
                "paper_id": paper_id,
                "status": "processed",
                "text_extracted": ok_text,
                "text_quality": text_quality.get("quality"),
                "figure_count": figure_summary.get("kept_count", 0),
                "equation_count": len(equation_candidates),
                "metadata_path": str(metadata_path.resolve()),
                "text_path": str(text_path.resolve()),
            }
        )

        print(
            f"[ok] {paper_id} | text={text_quality.get('quality')} | "
            f"eq={len(equation_candidates)} | figs={figure_summary.get('kept_count', 0)}"
        )

    summary = {
        "generated_at_utc": utc_now_iso(),
        "manifest": str(manifest_path.resolve()),
        "total_records": len(extraction_rows),
        "processed_records": sum(1 for row in extraction_rows if row.get("status") == "processed"),
        "skipped_records": sum(1 for row in extraction_rows if row.get("status") == "skipped"),
        "rows": extraction_rows,
    }
    json_dump(out_dir / "extraction_summary.json", summary)

    print(json.dumps(
        {
            "out_dir": str(out_dir.resolve()),
            "extraction_summary": str((out_dir / "extraction_summary.json").resolve()),
            "processed": summary["processed_records"],
            "skipped": summary["skipped_records"],
        },
        indent=2,
    ))


def parse_args() -> argparse.Namespace:
    repo_root = repo_root_from_file(Path(__file__))
    default_out = repo_root / "Artifacts" / "research_report_2026-02-11"

    parser = argparse.ArgumentParser(description="Extract raw assets from manifest-defined PDF corpus.")
    parser.add_argument("--manifest", type=Path, default=default_out / "manifest_unique.json")
    parser.add_argument("--out-dir", type=Path, default=default_out)
    parser.add_argument("--ris", type=Path, default=repo_root / "Research Papers" / "MECH0020.ris")
    parser.add_argument("--force", action="store_true", help="Regenerate all paper assets.")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    manifest = args.manifest.resolve()
    out_dir = ensure_dir(args.out_dir.resolve())
    ris = args.ris.resolve()

    if not manifest.exists():
        raise SystemExit(f"manifest not found: {manifest}")

    extract_assets(manifest, out_dir, ris, force=args.force)


if __name__ == "__main__":
    main()
