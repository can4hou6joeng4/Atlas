#!/usr/bin/env python3
"""Generate CHANGELOG.md from the same source of truth as the in-app release history.

This reuses ``release_notes_lib`` (Conventional Commits parsing + grouping) and the
per-tag override files under ``release-notes/history/v*.json`` so that the repository
CHANGELOG, the in-app release history, and the Sparkle notes never drift apart.

Usage:
    python3 scripts/generate-changelog.py            # write CHANGELOG.md
    python3 scripts/generate-changelog.py --stdout   # print, do not write
    python3 scripts/generate-changelog.py --check     # exit 1 if CHANGELOG.md is stale (CI)
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import release_notes_lib as rnl

REPO = Path(__file__).resolve().parent.parent
HISTORY_DIR = REPO / "release-notes" / "history"
CHANGELOG = REPO / "CHANGELOG.md"
REPO_URL = "https://github.com/can4hou6joeng4/TokenAtlas"

HEADER = """\
# Changelog

All notable changes to TokenAtlas are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

This file is generated from the same source of truth as the in-app release history:
Conventional Commit messages (grouped by `scripts/release_notes_lib.py`) and the
per-release overrides in `release-notes/history/v*.json`. Regenerate it with:

```bash
python3 scripts/generate-changelog.py
```
"""


def tag_date(tag: str) -> str:
    out = subprocess.check_output(
        ["git", "-C", str(REPO), "log", "-1", "--format=%ad", "--date=format:%Y-%m-%d", tag],
        text=True,
    )
    return out.strip()


def load_override(tag: str) -> dict | None:
    path = HISTORY_DIR / f"{tag}.json"
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def render_grouped(grouped: dict[str, list[str]]) -> list[str]:
    lines: list[str] = []
    for group in rnl.GROUP_ORDER:
        items = grouped.get(group)
        if not items:
            continue
        lines.append(f"### {group}")
        lines.append("")
        for item in items:
            lines.append(f"- {item}")
        lines.append("")
    return lines


def grouped_subjects(notes: list) -> dict[str, list[str]]:
    """Group commits by their (deduplicated) subject summaries.

    The in-app release history expands each commit body into bullet items, but for
    the human-facing CHANGELOG a single clean line per commit (the Conventional
    Commit summary) reads better and avoids depending on body formatting.
    """
    grouped: dict[str, list[str]] = {group: [] for group in rnl.GROUP_ORDER}
    for note in notes:
        _, summary = rnl.parse_type_and_summary(note.subject)
        summary = (summary or note.subject).strip()
        bucket = grouped.setdefault(note.group, [])
        if summary and summary not in bucket:
            bucket.append(summary)
    return grouped


def render_unreleased(latest_tag: str | None) -> list[str]:
    ref_from = latest_tag if latest_tag else None
    notes = rnl.read_commits(REPO, "HEAD", ref_from)
    grouped = grouped_subjects(notes)
    has_any = any(grouped.get(g) for g in rnl.GROUP_ORDER)
    lines = ["## [Unreleased]", ""]
    if not has_any:
        lines.append("_No unreleased changes._")
        lines.append("")
        return lines
    lines.extend(render_grouped(grouped))
    return lines


def render_release(tag: str, previous: str | None) -> list[str]:
    version = tag[1:] if tag.startswith("v") else tag
    date = tag_date(tag)
    lines = [f"## [{version}] - {date}", ""]

    override = load_override(tag)
    if override:
        headline = override.get("headline")
        if headline:
            lines.append(f"_{headline}_")
            lines.append("")
        for change in override.get("changes", []):
            lines.append(f"- {change}")
        lines.append("")
        return lines

    notes = rnl.read_commits(REPO, tag, previous)
    grouped = rnl.grouped_notes(notes)
    if any(grouped.get(g) for g in rnl.GROUP_ORDER):
        lines.extend(render_grouped(grouped))
    else:
        lines.append("- Maintenance release.")
        lines.append("")
    return lines


def build() -> str:
    tags = rnl.semver_tags(REPO)  # ascending
    latest = tags[-1] if tags else None

    blocks: list[str] = [HEADER]
    blocks.append("\n".join(render_unreleased(latest)).rstrip() + "\n")

    for idx in range(len(tags) - 1, -1, -1):
        tag = tags[idx]
        previous = tags[idx - 1] if idx > 0 else None
        blocks.append("\n".join(render_release(tag, previous)).rstrip() + "\n")

    # Link references
    refs: list[str] = []
    if latest:
        refs.append(f"[Unreleased]: {REPO_URL}/compare/{latest}...HEAD")
    else:
        refs.append(f"[Unreleased]: {REPO_URL}/commits/main")
    for idx in range(len(tags) - 1, -1, -1):
        tag = tags[idx]
        version = tag[1:] if tag.startswith("v") else tag
        previous = tags[idx - 1] if idx > 0 else None
        if previous:
            refs.append(f"[{version}]: {REPO_URL}/compare/{previous}...{tag}")
        else:
            refs.append(f"[{version}]: {REPO_URL}/releases/tag/{tag}")

    body = "\n".join(blocks).rstrip() + "\n\n" + "\n".join(refs) + "\n"
    return body


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate CHANGELOG.md")
    parser.add_argument("--stdout", action="store_true", help="print instead of writing")
    parser.add_argument("--check", action="store_true", help="exit 1 if CHANGELOG.md is out of date")
    args = parser.parse_args()

    content = build()

    if args.stdout:
        sys.stdout.write(content)
        return 0

    if args.check:
        current = CHANGELOG.read_text(encoding="utf-8") if CHANGELOG.exists() else ""
        if current != content:
            sys.stderr.write("CHANGELOG.md is out of date. Run: python3 scripts/generate-changelog.py\n")
            return 1
        print("CHANGELOG.md is up to date.")
        return 0

    CHANGELOG.write_text(content, encoding="utf-8")
    print(f"Wrote {CHANGELOG.relative_to(REPO)} ({len(content.splitlines())} lines).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
