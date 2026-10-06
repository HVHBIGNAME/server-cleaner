#!/usr/bin/env python3
"""Render a Server Cleaner JSON report as a standalone, dependency-free SVG."""

import argparse
import json
import sys
from collections import Counter
from html import escape
from pathlib import Path

PALETTES = {
    "dark": {"bg": "#101310", "panel": "#171c16", "line": "#30392c", "fg": "#f0f2e8", "muted": "#a1ad9b", "accent": "#d2ff5a", "free": "#344620", "error": "#ff9685"},
    "light": {"bg": "#f3f2e9", "panel": "#e9ebdf", "line": "#cdd3c0", "fg": "#20271b", "muted": "#616d55", "accent": "#496817", "free": "#dce8bd", "error": "#ac362a"},
}
STATUSES = ("completed", "planned", "skipped", "failed")


def validate_report(report):
    if not isinstance(report, dict) or report.get("schema_version") != 1:
        raise ValueError("expected a Server Cleaner report with schema_version=1")
    if report.get("mode") not in ("preview", "apply", "capabilities"):
        raise ValueError("unknown report mode")
    tasks = report.get("tasks")
    if not isinstance(tasks, list) or len(tasks) > 64:
        raise ValueError("tasks must be a list with at most 64 entries")
    for task in tasks:
        if not isinstance(task, dict) or task.get("status") not in STATUSES or not isinstance(task.get("id"), str):
            raise ValueError("invalid task entry")
    counts = Counter(task["status"] for task in tasks)
    summary = report.get("summary")
    if not isinstance(summary, dict) or any(type(summary.get(status)) is not int or summary[status] != counts[status] for status in STATUSES):
        raise ValueError("summary does not match task results")
    disk = report.get("disk")
    if not isinstance(disk, dict) or not isinstance(disk.get("path"), str):
        raise TypeError("missing disk information")
    for key in ("before", "after"):
        snapshot = disk.get(key)
        if snapshot is None:
            continue
        if not isinstance(snapshot, dict):
            raise TypeError(f"invalid {key} disk snapshot")
        for field in ("size_kib", "used_kib", "available_kib"):
            value = snapshot.get(field)
            if type(value) is not int or abs(value) > 2**63 - 1:
                raise ValueError(f"invalid {key}.{field}")
            if field != "available_kib" and value < 0:
                raise ValueError(f"negative {key}.{field}")
    if report["mode"] != "apply" and disk.get("after") is not None:
        raise ValueError("a preview cannot contain post-cleanup measurements")
    return report


def svg_text(x, y, content, fill, size=16, weight=400, extra=""):
    return f'<text x="{x}" y="{y}" font-size="{size}" font-weight="{weight}" fill="{fill}" {extra}>{escape(str(content))}</text>'


def disk_row(snapshot, y, label, palette):
    parts = [svg_text(44, y, label, palette["muted"], 13, extra='class="mono"')]
    parts.append(f'<rect x="44" y="{y + 18}" width="650" height="28" rx="4" fill="{palette["line"]}"/>')
    if snapshot is None:
        parts.append(svg_text(44, y + 75, "No measurement / not executed", palette["muted"]))
        return parts
    total = snapshot["size_kib"]
    used = min(1, max(0, snapshot["used_kib"] / total)) if total else 0
    available = min(1 - used, max(0, snapshot["available_kib"] / total)) if total else 0
    used_width, free_width = 650 * used, 650 * available
    parts.append(f'<rect x="44" y="{y + 18}" width="{used_width:.2f}" height="28" fill="{palette["accent"]}"/>')
    parts.append(f'<rect x="{44 + used_width:.2f}" y="{y + 18}" width="{free_width:.2f}" height="28" fill="{palette["free"]}"/>')
    detail = f'{snapshot["used_kib"] / 1048576:.2f} GiB used  /  {snapshot["available_kib"] / 1048576:.2f} GiB available'
    parts.append(svg_text(44, y + 75, detail, palette["fg"]))
    return parts


def render_report(report, theme="dark", title="SERVER CLEANER / RUN REPORT"):
    validate_report(report)
    if theme not in PALETTES:
        raise ValueError("theme must be dark or light")
    if len(title) > 64:
        raise ValueError("title must be at most 64 characters")
    p = PALETTES[theme]
    disk = report["disk"]
    summary = report["summary"]
    total_tasks = len(report["tasks"])
    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" width="1100" height="570" viewBox="0 0 1100 570" role="img" aria-labelledby="title desc">',
        f'<title id="title">{escape(title)}</title>',
        '<desc id="desc">Filesystem capacity before and after a maintenance run, with task outcomes. Available-space changes include concurrent writes and are not an attribution of reclaimed bytes.</desc>',
        '<style>text{font-family:Arial,Helvetica,sans-serif}.mono{font-family:Courier New,Courier,monospace}</style>',
        f'<rect x="0.5" y="0.5" width="1099" height="569" rx="18" fill="{p["bg"]}" stroke="{p["line"]}"/>',
        f'<path d="M32 78H1068M32 492H1068" stroke="{p["line"]}"/>',
        svg_text(44, 49, title, p["fg"], 18, 700),
        svg_text(1056, 49, report["mode"].upper(), p["accent"], 13, extra='text-anchor="end" class="mono"'),
        svg_text(42, 151, "Capacity, with context.", p["fg"], 50, 800),
        svg_text(44, 184, f'Filesystem: {disk["path"]}  /  {total_tasks} selected tasks', p["muted"], 16),
        f'<path d="M752 215V462" stroke="{p["line"]}"/>',
    ]
    parts.extend(disk_row(disk.get("before"), 237, "BEFORE", p))
    parts.extend(disk_row(disk.get("after"), 353, "AFTER", p))
    for index, status in enumerate(STATUSES):
        y = 241 + index * 56
        color = p["error"] if status == "failed" else p["accent"] if status == "completed" else p["muted"]
        parts.append(svg_text(800, y, status.upper(), p["muted"], 12, extra='class="mono"'))
        parts.append(svg_text(1056, y, summary[status], color, 24, 700, 'text-anchor="end"'))
        width = 256 * summary[status] / total_tasks if total_tasks else 0
        parts.append(f'<rect x="800" y="{y + 11}" width="256" height="4" fill="{p["line"]}"/>')
        parts.append(f'<rect x="800" y="{y + 11}" width="{width:.2f}" height="4" fill="{color}"/>')
    if disk.get("before") is not None and disk.get("after") is not None:
        delta = (disk["after"]["available_kib"] - disk["before"]["available_kib"]) / 1048576
        footer = f'Available-space change: {delta:+.2f} GiB'
    elif report["mode"] == "apply":
        footer = "No post-run measurement available"
    else:
        footer = "Preview / no post-cleanup measurement"
    parts.extend([
        svg_text(44, 525, footer, p["accent"], 17, 700),
        svg_text(44, 550, "Root filesystem only. Includes other processes; not a reclaimed-space estimate.", p["muted"], 12),
        svg_text(1056, 525, "HVHBIGNAME / 02", p["muted"], 12, extra='text-anchor="end" class="mono"'),
        "</svg>",
    ])
    return "\n".join(parts) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("report", help="JSON file, or - for stdin")
    parser.add_argument("--theme", choices=PALETTES, default="dark")
    parser.add_argument("--title", default="SERVER CLEANER / RUN REPORT")
    args = parser.parse_args()
    try:
        if args.report == "-":
            report = json.load(sys.stdin)
        else:
            with Path(args.report).open(encoding="utf-8") as source:
                report = json.load(source)
        svg = render_report(report, args.theme, args.title)
    except (OSError, ValueError, TypeError) as error:
        parser.error(str(error))
    sys.stdout.write(svg)


if __name__ == "__main__":
    main()
