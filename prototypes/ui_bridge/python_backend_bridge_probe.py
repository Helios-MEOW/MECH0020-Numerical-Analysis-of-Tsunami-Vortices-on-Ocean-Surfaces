#!/usr/bin/env python3
"""
python_backend_bridge_probe.py

Minimal backend/frontend bridge probe:
- Reads telemetry JSON produced by MATLAB.
- Optionally shows a short-lived Tk popup.
- Writes normalized summary JSON for MATLAB to consume.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="MATLAB-Python bridge probe")
    parser.add_argument("--input", required=True, help="Input telemetry JSON path")
    parser.add_argument("--output", required=True, help="Output summary JSON path")
    parser.add_argument("--no-popup", action="store_true", help="Skip popup rendering")
    parser.add_argument("--popup-seconds", type=float, default=1.2, help="Popup auto-close duration")
    return parser.parse_args()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def try_popup(summary_text: str, seconds: float) -> tuple[bool, str]:
    try:
        import tkinter as tk
    except Exception as exc:  # pragma: no cover
        return False, f"tkinter unavailable: {exc}"

    try:
        root = tk.Tk()
        root.title("MECH0020 Bridge Probe")
        root.geometry("520x180")
        root.configure(bg="#101316")
        label = tk.Label(
            root,
            text=summary_text,
            justify="left",
            font=("Consolas", 10),
            fg="#d8e1ea",
            bg="#101316",
            anchor="w",
        )
        label.pack(fill="both", expand=True, padx=12, pady=12)
        root.after(max(1, int(seconds * 1000)), root.destroy)
        root.mainloop()
        return True, "popup rendered"
    except Exception as exc:  # pragma: no cover
        return False, f"popup failed: {exc}"


def main() -> int:
    args = parse_args()
    input_path = Path(args.input).resolve()
    output_path = Path(args.output).resolve()

    if not input_path.exists():
        write_json(
            output_path,
            {
                "ok": False,
                "error": f"input not found: {input_path}",
                "popup_attempted": False,
                "popup_ok": False,
            },
        )
        return 2

    telemetry = load_json(input_path)
    method = str(telemetry.get("method", "unknown"))
    mode = str(telemetry.get("mode", "unknown"))
    iteration = telemetry.get("iteration", "n/a")
    runtime_s = telemetry.get("runtime_s", "n/a")
    max_omega = telemetry.get("max_omega", "n/a")

    summary_lines = [
        f"Method: {method}",
        f"Mode: {mode}",
        f"Iteration: {iteration}",
        f"Runtime [s]: {runtime_s}",
        f"Max |omega|: {max_omega}",
    ]
    summary_text = "\n".join(summary_lines)

    popup_attempted = not args.no_popup
    popup_ok = False
    popup_note = "popup skipped (--no-popup)"
    if popup_attempted:
        popup_ok, popup_note = try_popup(summary_text, args.popup_seconds)

    result = {
        "ok": True,
        "popup_attempted": popup_attempted,
        "popup_ok": popup_ok,
        "popup_note": popup_note,
        "summary": {
            "method": method,
            "mode": mode,
            "iteration": iteration,
            "runtime_s": runtime_s,
            "max_omega": max_omega,
        },
        "summary_text": summary_text,
    }
    write_json(output_path, result)
    print(output_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
