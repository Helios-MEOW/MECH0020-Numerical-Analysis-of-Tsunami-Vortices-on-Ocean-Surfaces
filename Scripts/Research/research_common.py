#!/usr/bin/env python3
"""Shared utilities for the research synthesis pipeline."""

from __future__ import annotations

import hashlib
import json
import re
import subprocess
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

DOI_REGEX = re.compile(r"10\.\d{4,9}/[-._;()/:A-Z0-9]+", re.IGNORECASE)
YEAR_REGEX = re.compile(r"\b(19|20)\d{2}\b")


@dataclass
class CommandResult:
    code: int
    stdout: str
    stderr: str


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def ensure_dir(path: Path) -> Path:
    path.mkdir(parents=True, exist_ok=True)
    return path


def repo_root_from_file(file_path: Path) -> Path:
    return file_path.resolve().parents[2]


def sha256_file(path: Path, chunk_size: int = 1024 * 1024) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while True:
            block = handle.read(chunk_size)
            if not block:
                break
            digest.update(block)
    return digest.hexdigest()


def run_command(
    cmd: Sequence[str],
    timeout: int = 300,
    cwd: Optional[Path] = None,
) -> CommandResult:
    proc = subprocess.run(
        list(cmd),
        cwd=str(cwd) if cwd else None,
        capture_output=True,
        timeout=timeout,
        text=True,
        encoding="utf-8",
        errors="ignore",
        check=False,
    )
    return CommandResult(code=proc.returncode, stdout=proc.stdout, stderr=proc.stderr)


def parse_pdfinfo_pages(pdfinfo_stdout: str) -> Optional[int]:
    match = re.search(r"^Pages:\s*(\d+)", pdfinfo_stdout, re.MULTILINE)
    if not match:
        return None
    return int(match.group(1))


def parse_size_token(size_token: str) -> int:
    token = size_token.strip().upper()
    unit = token[-1]
    if unit.isdigit():
        try:
            return int(float(token))
        except ValueError:
            return 0
    value = token[:-1]
    try:
        scalar = float(value)
    except ValueError:
        return 0
    if unit == "B":
        return int(scalar)
    if unit == "K":
        return int(scalar * 1024)
    if unit == "M":
        return int(scalar * 1024 * 1024)
    if unit == "G":
        return int(scalar * 1024 * 1024 * 1024)
    return int(scalar)


def clean_whitespace(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip()


def normalize_title(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", text.lower())


def safe_slug(text: str, max_len: int = 64) -> str:
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", text).strip("-").lower()
    if not slug:
        slug = "paper"
    return slug[:max_len]


def detect_doi(text: str) -> Optional[str]:
    match = DOI_REGEX.search(text)
    if not match:
        return None
    return match.group(0).rstrip(".,);]")


def detect_year(text: str) -> Optional[int]:
    years = [int(match.group(0)) for match in re.finditer(r"\b(19|20)\d{2}\b", text)]
    if not years:
        return None
    return years[0]


def split_pages_from_pdftotext(full_text: str) -> List[str]:
    # pdftotext uses form feed as page separator.
    pages = full_text.split("\f")
    if pages and pages[-1].strip() == "":
        pages = pages[:-1]
    return pages


def sentence_tokenize(text: str) -> List[str]:
    flat = clean_whitespace(text)
    if not flat:
        return []
    parts = re.split(r"(?<=[.!?])\s+", flat)
    return [p.strip() for p in parts if p.strip()]


def parse_ris_file(path: Path) -> List[Dict[str, object]]:
    if not path.exists():
        return []
    content = path.read_text(encoding="utf-8", errors="ignore")
    raw_entries = content.split("ER  -")
    entries: List[Dict[str, object]] = []
    for raw in raw_entries:
        if "TY  -" not in raw:
            continue
        entry: Dict[str, object] = {
            "type": "",
            "authors": [],
            "title": "",
            "journal": "",
            "year": "",
            "doi": "",
            "url": "",
            "volume": "",
            "issue": "",
            "sp": "",
            "ep": "",
            "publisher": "",
        }
        for line in raw.splitlines():
            if " - " not in line:
                continue
            tag, value = line.split(" - ", 1)
            tag = tag.strip()
            value = value.strip()
            if not value:
                continue
            if tag == "TY":
                entry["type"] = value
            elif tag == "AU":
                cast = entry.get("authors", [])
                if isinstance(cast, list):
                    cast.append(value)
                    entry["authors"] = cast
            elif tag in {"T1", "TI"}:
                entry["title"] = value
            elif tag in {"T2", "JO", "JA", "JF"}:
                if not entry.get("journal"):
                    entry["journal"] = value
            elif tag == "PY":
                entry["year"] = value[:4]
            elif tag == "DO":
                entry["doi"] = value
            elif tag == "UR":
                entry["url"] = value
            elif tag == "VL":
                entry["volume"] = value
            elif tag == "IS":
                entry["issue"] = value
            elif tag == "SP":
                entry["sp"] = value
            elif tag == "EP":
                entry["ep"] = value
            elif tag == "PB":
                entry["publisher"] = value
        entries.append(entry)
    return entries


def build_ris_indexes(entries: List[Dict[str, object]]) -> Tuple[Dict[str, Dict[str, object]], Dict[str, Dict[str, object]]]:
    by_doi: Dict[str, Dict[str, object]] = {}
    by_title: Dict[str, Dict[str, object]] = {}
    for entry in entries:
        doi = str(entry.get("doi", "")).strip().lower()
        title = str(entry.get("title", "")).strip()
        if doi:
            by_doi[doi] = entry
        if title:
            by_title[normalize_title(title)] = entry
    return by_doi, by_title


def find_ris_match(
    doi: Optional[str],
    title: Optional[str],
    by_doi: Dict[str, Dict[str, object]],
    by_title: Dict[str, Dict[str, object]],
) -> Optional[Dict[str, object]]:
    if doi:
        candidate = by_doi.get(doi.lower())
        if candidate:
            return candidate
    if title:
        norm = normalize_title(title)
        candidate = by_title.get(norm)
        if candidate:
            return candidate
        # relaxed contains check
        for key, entry in by_title.items():
            if norm and (norm in key or key in norm):
                return entry
    return None


def extract_title_from_page(page_text: str) -> str:
    lines = [clean_whitespace(line) for line in page_text.splitlines()]
    lines = [line for line in lines if line]
    banned_prefixes = (
        "downloaded from",
        "contents",
        "keywords",
        "research",
        "accepted",
        "doi",
        "http",
        "www",
        "open access",
        "journal",
        "article",
        "available online",
    )
    candidates: List[str] = []
    for line in lines[:50]:
        lower = line.lower()
        if any(lower.startswith(prefix) for prefix in banned_prefixes):
            continue
        if len(line) < 10:
            continue
        if re.fullmatch(r"[0-9.\- ]+", line):
            continue
        candidates.append(line)
    if not candidates:
        return ""
    title = candidates[0]
    if len(candidates) > 1 and len(title) < 90:
        nxt = candidates[1]
        if len(nxt) < 90 and not nxt.endswith(":"):
            if title[-1].isalnum() and nxt[0].isalnum():
                joined = f"{title} {nxt}"
                if len(joined) <= 180:
                    title = joined
    return title


def to_vancouver_citation(entry: Dict[str, object], fallback_title: str, fallback_url: str = "") -> str:
    authors = entry.get("authors") if isinstance(entry.get("authors"), list) else []
    author_txt = ", ".join(str(a).strip() for a in authors if str(a).strip())
    title = str(entry.get("title", "")).strip() or fallback_title
    journal = str(entry.get("journal", "")).strip()
    year = str(entry.get("year", "")).strip()
    volume = str(entry.get("volume", "")).strip()
    issue = str(entry.get("issue", "")).strip()
    sp = str(entry.get("sp", "")).strip()
    ep = str(entry.get("ep", "")).strip()
    doi = str(entry.get("doi", "")).strip()
    url = str(entry.get("url", "")).strip() or fallback_url

    parts: List[str] = []
    if author_txt:
        parts.append(f"{author_txt}.")
    if title:
        parts.append(f"{title}.")
    if journal:
        vol_issue = ""
        if volume and issue:
            vol_issue = f"{volume}({issue})"
        elif volume:
            vol_issue = volume
        elif issue:
            vol_issue = f"({issue})"
        pages = ""
        if sp and ep:
            pages = f":{sp}-{ep}"
        elif sp:
            pages = f":{sp}"
        yblock = year + ";" if year else ""
        parts.append(f"{journal}. {yblock}{vol_issue}{pages}.")
    elif year:
        parts.append(f"{year}.")

    if doi:
        parts.append(f"doi:{doi}.")
    if url:
        parts.append(f"Available from: {url}.")
    if not parts:
        return fallback_title
    return " ".join(parts)


def json_dump(path: Path, data: object) -> None:
    ensure_dir(path.parent)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")


def chunked(items: Sequence[object], size: int) -> Iterable[Sequence[object]]:
    if size <= 0:
        raise ValueError("chunk size must be > 0")
    for idx in range(0, len(items), size):
        yield items[idx : idx + size]


def relative_repo_path(path: Path, repo_root: Path) -> str:
    try:
        return path.resolve().relative_to(repo_root.resolve()).as_posix()
    except Exception:
        return path.as_posix()
