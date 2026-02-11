#!/usr/bin/env python3
"""Build corpus manifest and deduplicate PDF records."""

from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path
from typing import Dict, List

from research_common import (
    ensure_dir,
    json_dump,
    parse_pdfinfo_pages,
    relative_repo_path,
    repo_root_from_file,
    run_command,
    sha256_file,
    utc_now_iso,
)


def probe_extractability(pdf_path: Path, staging_dir: Path) -> Dict[str, str]:
    direct = run_command(["pdftotext", "-f", "1", "-l", "1", str(pdf_path), "-"], timeout=90)
    if direct.code == 0 and direct.stdout.strip():
        return {"status": "direct_ok", "note": "pdftotext direct path succeeded"}

    stage_path = staging_dir / (pdf_path.stem.encode("ascii", "ignore").decode("ascii") or "paper")
    stage_path = stage_path.with_suffix(".pdf")
    idx = 1
    while stage_path.exists():
        stage_path = staging_dir / f"{stage_path.stem}_{idx}.pdf"
        idx += 1

    try:
        shutil.copy2(pdf_path, stage_path)
    except Exception as exc:
        return {"status": "failed", "note": f"direct failed; staging copy failed: {exc}"}

    staged = run_command(["pdftotext", "-f", "1", "-l", "1", str(stage_path), "-"], timeout=90)
    if staged.code == 0 and staged.stdout.strip():
        return {"status": "requires_staging", "note": "pdftotext succeeds only with ASCII staging path"}

    return {
        "status": "failed",
        "note": "pdftotext failed on direct and staged path",
    }


def build_manifest(papers_dir: Path, out_dir: Path) -> None:
    repo_root = repo_root_from_file(Path(__file__))
    staging_probe_dir = ensure_dir(out_dir / "temp_probe")

    pdf_files = sorted(papers_dir.glob("*.pdf"), key=lambda p: p.name.lower())
    records: List[Dict[str, object]] = []

    for pdf in pdf_files:
        size_bytes = pdf.stat().st_size
        sha256 = sha256_file(pdf)

        info = run_command(["pdfinfo", str(pdf)], timeout=120)
        pages = parse_pdfinfo_pages(info.stdout) if info.code == 0 else None

        extract_probe = probe_extractability(pdf, staging_probe_dir)

        record: Dict[str, object] = {
            "file_name": pdf.name,
            "absolute_path": str(pdf.resolve()),
            "relative_path": relative_repo_path(pdf, repo_root),
            "sha256": sha256,
            "size_bytes": size_bytes,
            "pages": pages,
            "extractability_status": extract_probe["status"],
            "extractability_note": extract_probe["note"],
        }
        records.append(record)

    groups: Dict[str, List[Dict[str, object]]] = {}
    for record in records:
        groups.setdefault(str(record["sha256"]), []).append(record)

    unique_records: List[Dict[str, object]] = []
    duplicate_groups = []

    group_items = sorted(groups.items(), key=lambda kv: sorted(x["file_name"] for x in kv[1])[0].lower())
    for idx, (sha256, group_records) in enumerate(group_items, start=1):
        sorted_group = sorted(group_records, key=lambda r: str(r["file_name"]).lower())
        canonical = sorted_group[0]
        aliases = [str(item["file_name"]) for item in sorted_group]
        duplicate_groups.append(aliases)

        paper_id = f"paper_{idx:03d}_{sha256[:8]}"
        unique_record: Dict[str, object] = {
            "paper_id": paper_id,
            "sha256": sha256,
            "canonical_file_name": canonical["file_name"],
            "canonical_absolute_path": canonical["absolute_path"],
            "canonical_relative_path": canonical["relative_path"],
            "size_bytes": canonical["size_bytes"],
            "pages": canonical["pages"],
            "extractability_status": canonical["extractability_status"],
            "extractability_note": canonical["extractability_note"],
            "alias_file_names": aliases,
            "duplicate_count": max(0, len(aliases) - 1),
        }
        unique_records.append(unique_record)

    manifest_all = {
        "generated_at_utc": utc_now_iso(),
        "papers_dir": str(papers_dir.resolve()),
        "total_files": len(records),
        "unique_files": len(unique_records),
        "duplicate_groups": sum(1 for group in duplicate_groups if len(group) > 1),
        "records": records,
        "duplicate_groups_detail": duplicate_groups,
    }

    manifest_unique = {
        "generated_at_utc": utc_now_iso(),
        "source_total_files": len(records),
        "source_unique_files": len(unique_records),
        "papers": unique_records,
    }

    json_dump(out_dir / "manifest_all.json", manifest_all)
    json_dump(out_dir / "manifest_unique.json", manifest_unique)

    if staging_probe_dir.exists():
        shutil.rmtree(staging_probe_dir, ignore_errors=True)

    print(json.dumps(
        {
            "manifest_all": str((out_dir / "manifest_all.json").resolve()),
            "manifest_unique": str((out_dir / "manifest_unique.json").resolve()),
            "total_files": len(records),
            "unique_files": len(unique_records),
            "duplicate_groups": sum(1 for group in duplicate_groups if len(group) > 1),
        },
        indent=2,
    ))


def parse_args() -> argparse.Namespace:
    repo_root = repo_root_from_file(Path(__file__))
    default_out = repo_root / "Artifacts" / "research_report_2026-02-11"
    default_papers = repo_root / "Research Papers"

    parser = argparse.ArgumentParser(description="Build PDF corpus manifest with deduplication.")
    parser.add_argument("--papers-dir", type=Path, default=default_papers)
    parser.add_argument("--out-dir", type=Path, default=default_out)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    papers_dir = args.papers_dir.resolve()
    out_dir = ensure_dir(args.out_dir.resolve())

    if not papers_dir.exists():
        raise SystemExit(f"papers directory does not exist: {papers_dir}")

    build_manifest(papers_dir, out_dir)


if __name__ == "__main__":
    main()
