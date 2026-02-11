#!/usr/bin/env python3
"""Publish consolidated markdown report into Notion as a child page."""

from __future__ import annotations

import argparse
import json
import math
import mimetypes
import os
import re
import time
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

import requests

from research_common import chunked, ensure_dir, repo_root_from_file, utc_now_iso

NOTION_API_BASE = "https://api.notion.com/v1"
DEFAULT_NOTION_VERSION = "2025-09-03"

HEADING_RE = re.compile(r"^(#{1,3})\s+(.*)$")
BULLET_RE = re.compile(r"^-\s+(.*)$")
NUMBERED_RE = re.compile(r"^\d+\.\s+(.*)$")
IMAGE_MD_RE = re.compile(r"^!\[(.*?)\]\((.*?)\)$")


def notion_headers(token: str, notion_version: str) -> Dict[str, str]:
    return {
        "Authorization": f"Bearer {token}",
        "Notion-Version": notion_version,
        "Content-Type": "application/json",
    }


def request_with_retry(
    method: str,
    url: str,
    headers: Dict[str, str],
    json_payload: Optional[Dict[str, object]] = None,
    files: Optional[Dict[str, object]] = None,
    timeout: int = 90,
    max_attempts: int = 6,
) -> requests.Response:
    last_error = None
    for attempt in range(1, max_attempts + 1):
        try:
            if files is None:
                response = requests.request(
                    method,
                    url,
                    headers=headers,
                    json=json_payload,
                    timeout=timeout,
                )
            else:
                # Multipart requests must not force JSON content-type.
                m_headers = {k: v for k, v in headers.items() if k.lower() != "content-type"}
                response = requests.request(
                    method,
                    url,
                    headers=m_headers,
                    files=files,
                    timeout=timeout,
                )
        except requests.RequestException as exc:
            last_error = exc
            sleep_s = min(30.0, 1.5**attempt)
            time.sleep(sleep_s)
            continue

        if response.status_code in {429, 500, 502, 503, 504} and attempt < max_attempts:
            retry_after = response.headers.get("Retry-After")
            if retry_after and retry_after.isdigit():
                sleep_s = float(retry_after)
            else:
                sleep_s = min(45.0, 1.8**attempt)
            time.sleep(sleep_s)
            continue

        return response

    raise RuntimeError(f"request failed after retries: {last_error}")


def rich_text(text: str) -> List[Dict[str, object]]:
    text = text.strip()
    if not text:
        return []
    chunks = []
    max_len = 1800
    for idx in range(0, len(text), max_len):
        part = text[idx : idx + max_len]
        chunks.append(
            {
                "type": "text",
                "text": {
                    "content": part,
                },
            }
        )
    return chunks


def paragraph_blocks(text: str) -> List[Dict[str, object]]:
    blocks: List[Dict[str, object]] = []
    text = text.strip()
    if not text:
        return blocks
    max_para_len = 1800 * 8
    for idx in range(0, len(text), max_para_len):
        part = text[idx : idx + max_para_len]
        blocks.append(
            {
                "object": "block",
                "type": "paragraph",
                "paragraph": {"rich_text": rich_text(part)},
            }
        )
    return blocks


def language_map(language: str) -> str:
    lang = language.strip().lower()
    allowed = {
        "abap",
        "arduino",
        "bash",
        "basic",
        "c",
        "clojure",
        "coffeescript",
        "c++",
        "c#",
        "css",
        "dart",
        "diff",
        "docker",
        "elixir",
        "elm",
        "erlang",
        "flow",
        "fortran",
        "f#",
        "gherkin",
        "glsl",
        "go",
        "graphql",
        "groovy",
        "haskell",
        "html",
        "java",
        "javascript",
        "json",
        "julia",
        "kotlin",
        "latex",
        "less",
        "lisp",
        "livescript",
        "lua",
        "makefile",
        "markdown",
        "markup",
        "matlab",
        "mermaid",
        "nix",
        "objective-c",
        "ocaml",
        "pascal",
        "perl",
        "php",
        "plain text",
        "powershell",
        "prolog",
        "protobuf",
        "python",
        "r",
        "reason",
        "ruby",
        "rust",
        "sass",
        "scala",
        "scheme",
        "scss",
        "shell",
        "sql",
        "swift",
        "typescript",
        "vb.net",
        "verilog",
        "vhdl",
        "visual basic",
        "webassembly",
        "xml",
        "yaml",
    }
    if lang in allowed:
        return lang
    if lang in {"sh", "zsh"}:
        return "shell"
    if lang in {"ps1", "pwsh"}:
        return "powershell"
    return "plain text"


def parse_markdown(
    markdown_text: str,
    markdown_path: Path,
    repo_root: Path,
    notion_token: str,
    notion_version: str,
    publish_log: List[Dict[str, object]],
) -> Tuple[List[Dict[str, object]], int, int]:
    lines = markdown_text.splitlines()
    blocks: List[Dict[str, object]] = []
    i = 0
    heading_count = 0
    image_count = 0

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if stripped == "":
            i += 1
            continue

        # Fenced code block.
        if stripped.startswith("```"):
            language = stripped[3:].strip() or "plain text"
            code_lines: List[str] = []
            i += 1
            while i < len(lines) and not lines[i].strip().startswith("```"):
                code_lines.append(lines[i])
                i += 1
            if i < len(lines) and lines[i].strip().startswith("```"):
                i += 1
            code_text = "\n".join(code_lines)
            blocks.append(
                {
                    "object": "block",
                    "type": "code",
                    "code": {
                        "rich_text": rich_text(code_text),
                        "caption": rich_text("mermaid") if language.strip().lower() == "mermaid" else [],
                        "language": language_map(language),
                    },
                }
            )
            continue

        # Equation block $$ ... $$ or multiline between markers.
        if stripped.startswith("$$"):
            if stripped.endswith("$$") and len(stripped) > 4:
                expr = stripped[2:-2].strip()
                i += 1
            else:
                expr_lines: List[str] = []
                i += 1
                while i < len(lines) and lines[i].strip() != "$$":
                    expr_lines.append(lines[i])
                    i += 1
                if i < len(lines) and lines[i].strip() == "$$":
                    i += 1
                expr = " ".join(clean for clean in expr_lines if clean.strip())
            expr = expr.strip()
            if expr:
                blocks.append(
                    {
                        "object": "block",
                        "type": "equation",
                        "equation": {
                            "expression": expr[:1000],
                        },
                    }
                )
            continue

        # Heading.
        hm = HEADING_RE.match(stripped)
        if hm:
            level = len(hm.group(1))
            text = hm.group(2).strip()
            level = max(1, min(level, 3))
            block_type = f"heading_{level}"
            blocks.append(
                {
                    "object": "block",
                    "type": block_type,
                    block_type: {
                        "rich_text": rich_text(text),
                    },
                }
            )
            heading_count += 1
            i += 1
            continue

        # Image markdown.
        im = IMAGE_MD_RE.match(stripped)
        if im:
            alt = im.group(1).strip() or "figure"
            raw_target = im.group(2).strip()
            image_block = None

            if raw_target.lower().startswith("http://") or raw_target.lower().startswith("https://"):
                image_block = {
                    "object": "block",
                    "type": "image",
                    "image": {
                        "type": "external",
                        "external": {"url": raw_target},
                        "caption": rich_text(alt),
                    },
                }
                publish_log.append({"event": "image_external", "target": raw_target})
            else:
                local_path = (markdown_path.parent / raw_target).resolve()
                if not local_path.exists():
                    local_path = (repo_root / raw_target).resolve()

                if local_path.exists():
                    upload_id = upload_file_to_notion(
                        local_path,
                        notion_token,
                        notion_version,
                        publish_log,
                    )
                    if upload_id:
                        image_block = {
                            "object": "block",
                            "type": "image",
                            "image": {
                                "type": "file_upload",
                                "file_upload": {"id": upload_id},
                                "caption": rich_text(alt),
                            },
                        }
                    else:
                        image_block = {
                            "object": "block",
                            "type": "paragraph",
                            "paragraph": {
                                "rich_text": rich_text(
                                    f"Image upload failed for local file: {raw_target}"
                                )
                            },
                        }
                else:
                    image_block = {
                        "object": "block",
                        "type": "paragraph",
                        "paragraph": {
                            "rich_text": rich_text(f"Image file not found: {raw_target}")
                        },
                    }

            if image_block is not None:
                blocks.append(image_block)
                image_count += 1

            i += 1
            continue

        # Bullet list.
        bm = BULLET_RE.match(stripped)
        if bm:
            blocks.append(
                {
                    "object": "block",
                    "type": "bulleted_list_item",
                    "bulleted_list_item": {
                        "rich_text": rich_text(bm.group(1).strip()),
                    },
                }
            )
            i += 1
            continue

        # Numbered list.
        nm = NUMBERED_RE.match(stripped)
        if nm:
            blocks.append(
                {
                    "object": "block",
                    "type": "numbered_list_item",
                    "numbered_list_item": {
                        "rich_text": rich_text(nm.group(1).strip()),
                    },
                }
            )
            i += 1
            continue

        # Paragraph/table fallback: collect contiguous plain lines.
        para_lines = [stripped]
        i += 1
        while i < len(lines):
            nxt = lines[i].strip()
            if not nxt:
                break
            if nxt.startswith("```"):
                break
            if nxt.startswith("#"):
                break
            if BULLET_RE.match(nxt) or NUMBERED_RE.match(nxt) or IMAGE_MD_RE.match(nxt):
                break
            if nxt.startswith("$$"):
                break
            para_lines.append(nxt)
            i += 1

        paragraph_text = " ".join(para_lines)
        blocks.extend(paragraph_blocks(paragraph_text))

    return blocks, heading_count, image_count


def create_child_page(
    parent_page_id: str,
    title: str,
    token: str,
    notion_version: str,
) -> Dict[str, object]:
    url = f"{NOTION_API_BASE}/pages"
    headers = notion_headers(token, notion_version)
    payload = {
        "parent": {"page_id": parent_page_id},
        "properties": {
            "title": {
                "title": [
                    {
                        "type": "text",
                        "text": {
                            "content": title[:200],
                        },
                    }
                ]
            }
        },
    }
    response = request_with_retry("POST", url, headers, json_payload=payload)
    if response.status_code >= 300:
        raise RuntimeError(f"failed to create page: {response.status_code} {response.text[:400]}")
    return response.json()


def append_blocks(
    block_id: str,
    blocks: Sequence[Dict[str, object]],
    token: str,
    notion_version: str,
    publish_log: List[Dict[str, object]],
) -> None:
    headers = notion_headers(token, notion_version)
    url = f"{NOTION_API_BASE}/blocks/{block_id}/children"

    for chunk_idx, chunk in enumerate(chunked(list(blocks), 100), start=1):
        payload = {"children": list(chunk)}
        response = request_with_retry("PATCH", url, headers, json_payload=payload)
        publish_log.append(
            {
                "event": "append_chunk",
                "chunk_index": chunk_idx,
                "chunk_size": len(chunk),
                "status_code": response.status_code,
            }
        )
        if response.status_code >= 300:
            raise RuntimeError(
                f"append blocks failed at chunk {chunk_idx}: {response.status_code} {response.text[:400]}"
            )


def upload_file_to_notion(
    file_path: Path,
    token: str,
    notion_version: str,
    publish_log: List[Dict[str, object]],
) -> Optional[str]:
    headers = notion_headers(token, notion_version)

    # 1) Create upload object.
    create_resp = request_with_retry(
        "POST",
        f"{NOTION_API_BASE}/file_uploads",
        headers,
        json_payload={},
    )
    publish_log.append(
        {
            "event": "file_upload_create",
            "file": str(file_path),
            "status_code": create_resp.status_code,
        }
    )
    if create_resp.status_code >= 300:
        return None

    create_json = create_resp.json()
    upload_id = create_json.get("id")
    if not upload_id:
        return None

    # 2) Send binary content.
    mime_type = mimetypes.guess_type(file_path.name)[0] or "application/octet-stream"
    with file_path.open("rb") as handle:
        send_resp = request_with_retry(
            "POST",
            f"{NOTION_API_BASE}/file_uploads/{upload_id}/send",
            headers,
            files={"file": (file_path.name, handle, mime_type)},
            timeout=180,
        )
    publish_log.append(
        {
            "event": "file_upload_send",
            "file": str(file_path),
            "upload_id": upload_id,
            "status_code": send_resp.status_code,
        }
    )
    if send_resp.status_code >= 300:
        return None

    # 3) Complete upload (if endpoint is supported for the current account/version).
    complete_resp = request_with_retry(
        "POST",
        f"{NOTION_API_BASE}/file_uploads/{upload_id}/complete",
        headers,
        json_payload={},
    )
    publish_log.append(
        {
            "event": "file_upload_complete",
            "file": str(file_path),
            "upload_id": upload_id,
            "status_code": complete_resp.status_code,
        }
    )

    if complete_resp.status_code >= 300 and complete_resp.status_code != 404:
        # Some Notion workspaces may auto-complete single-part upload;
        # keep upload id if send succeeded.
        pass

    return str(upload_id)


def publish_markdown(
    markdown_path: Path,
    parent_page_id: str,
    token_env: str,
    notion_version: str,
    title: str,
    artifacts_dir: Path,
) -> None:
    token = os.getenv(token_env, "").strip()
    if not token:
        raise SystemExit(f"environment variable `{token_env}` is not set")

    markdown_text = markdown_path.read_text(encoding="utf-8", errors="ignore")
    repo_root = repo_root_from_file(Path(__file__))

    publish_log: List[Dict[str, object]] = []

    blocks, heading_count, image_count = parse_markdown(
        markdown_text,
        markdown_path,
        repo_root,
        token,
        notion_version,
        publish_log,
    )

    page = create_child_page(parent_page_id, title, token, notion_version)
    page_id = str(page.get("id"))
    if not page_id:
        raise RuntimeError("page creation response did not contain id")

    append_blocks(page_id, blocks, token, notion_version, publish_log)

    notion_meta = {
        "published_at_utc": utc_now_iso(),
        "page_id": page_id,
        "page_url": page.get("url", ""),
        "parent_page_id": parent_page_id,
        "title": title,
        "notion_version": notion_version,
        "markdown_path": str(markdown_path.resolve()),
        "block_count": len(blocks),
        "heading_count_from_markdown": heading_count,
        "image_count_from_markdown": image_count,
    }

    ensure_dir(artifacts_dir)
    (artifacts_dir / "notion_page_meta.json").write_text(
        json.dumps(notion_meta, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    (artifacts_dir / "notion_publish_log.json").write_text(
        json.dumps(
            {
                "generated_at_utc": utc_now_iso(),
                "events": publish_log,
            },
            indent=2,
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )

    print(
        json.dumps(
            {
                "page_id": page_id,
                "page_url": notion_meta["page_url"],
                "block_count": len(blocks),
                "notion_page_meta": str((artifacts_dir / "notion_page_meta.json").resolve()),
                "notion_publish_log": str((artifacts_dir / "notion_publish_log.json").resolve()),
            },
            indent=2,
        )
    )


def parse_args() -> argparse.Namespace:
    repo_root = repo_root_from_file(Path(__file__))
    default_artifacts = repo_root / "Artifacts" / "research_report_2026-02-11"

    parser = argparse.ArgumentParser(description="Publish markdown report to Notion page.")
    parser.add_argument(
        "--markdown-path",
        type=Path,
        default=repo_root / "Markdowns" / "deep-research-report-2026-02-11.md",
    )
    parser.add_argument(
        "--parent-page-id",
        type=str,
        default="304abae6d98781c9b114c8a8834defd1",
    )
    parser.add_argument("--token-env", type=str, default="NOTION_API_KEY")
    parser.add_argument("--notion-version", type=str, default=DEFAULT_NOTION_VERSION)
    parser.add_argument(
        "--title",
        type=str,
        default="Deep Research Report - Tsunami Vorticity Corpus (2026-02-11)",
    )
    parser.add_argument(
        "--artifacts-dir",
        type=Path,
        default=default_artifacts,
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    publish_markdown(
        markdown_path=args.markdown_path.resolve(),
        parent_page_id=args.parent_page_id,
        token_env=args.token_env,
        notion_version=args.notion_version,
        title=args.title,
        artifacts_dir=args.artifacts_dir.resolve(),
    )


if __name__ == "__main__":
    main()
