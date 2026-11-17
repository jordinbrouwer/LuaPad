#!/usr/bin/env python3
"""Turn conventional commits since the latest release into a CHANGELOG release.

Prints the new version, or nothing when there is nothing to release.
"""
import argparse
import datetime
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lib import log  # noqa: E402

VERSION = r"[0-9]+\.[0-9]+\.[0-9]+"
COMMIT = re.compile(r"^(\w+)(?:\([^)]*\))?(!)?: (.+)$")
LEVELS = {"auto": 0, "patch": 1, "minor": 2, "major": 3}
BUMP = {"feat": 2, "fix": 1, "perf": 1}
SECTION = {"feat": "Added", "fix": "Fixed", "perf": "Changed"}
ORDER = ["Added", "Changed", "Deprecated", "Removed", "Fixed", "Security"]


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True, text=True).stdout


def commits(since):
    """(sha, subject, body) per commit since the tag that touches src/, oldest first."""
    history = git("log", "--no-merges", "--reverse", "--format=%H%x1f%s%x1f%b%x1e", f"{since}..HEAD", "--", "src")
    for entry in history.split("\x1e"):
        if entry.strip():
            sha, subject, body = entry.strip("\n").split("\x1f", 2)
            yield sha, subject, body


def sentence(text):
    text = text.strip()
    text = text[0].upper() + text[1:]
    return text if text[-1] in ".!?" else text + "."


def plan(entries, repo):
    level, notes = 0, {}
    for sha, subject, body in entries:
        match = COMMIT.match(subject)
        if not match:
            continue
        kind, bang, text = match.groups()
        breaking = bool(bang) or re.search(r"^BREAKING[ -]CHANGE:", body, re.M) is not None
        level = max(level, 3 if breaking else BUMP.get(kind, 0))
        section = SECTION.get(kind) or ("Changed" if breaking else None)
        if section:
            notes.setdefault(section, []).append(f"{sentence(text)} ([{sha[:7]}]({repo}/commit/{sha}))")
    return level, notes


def bumped(version, level):
    major, minor, patch = map(int, version.split("."))
    if level == 3:
        return f"{major + 1}.0.0"
    if level == 2:
        return f"{major}.{minor + 1}.0"
    return f"{major}.{minor}.{patch + 1}"


def merge(body, notes):
    """Unreleased text written by hand, plus the commit lines, grouped by section."""
    preamble, sections, current = [], {}, None
    for line in body.strip("\n").splitlines():
        heading = re.match(r"^### (.+)$", line)
        if heading:
            current = heading.group(1).strip()
            sections.setdefault(current, [])
        else:
            (sections[current] if current else preamble).append(line)
    for name, items in notes.items():
        lines = sections.setdefault(name, [])
        known = {line.strip().lower() for line in lines}
        lines.extend(f"- {item}" for item in items if f"- {item}".lower() not in known)
    parts = ["\n".join(preamble).strip()]
    for name in sorted(sections, key=lambda n: ORDER.index(n) if n in ORDER else len(ORDER)):
        lines = "\n".join(sections[name]).strip()
        if lines:
            parts.append(f"### {name}\n{lines}")
    return "\n\n".join(part for part in parts if part)


def unreleased(text):
    found = re.search(
        r"^## \[Unreleased\]\((?P<repo>\S+?)/compare/\S+?\.\.\.(?P<branch>[^)\s]+)\)\n(?P<body>.*?)(?=^## \[|\Z)",
        text,
        re.M | re.S,
    )
    if not found:
        log.fail("CHANGELOG.md needs '## [Unreleased](<repo>/compare/<version>...<branch>)'.")
    return found


def release(text, version, notes, date):
    found = unreleased(text)
    body = merge(found["body"], notes)
    if not body:
        log.fail("Nothing to put in the release notes.")
    repo = found["repo"]
    section = (
        f"## [Unreleased]({repo}/compare/{version}...{found['branch']})\n\n"
        f"## [{version} ({date})]({repo}/releases/tag/{version})\n\n{body}\n\n"
    )
    return text[: found.start()] + section + text[found.end():]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bump", choices=LEVELS, default="auto", help="auto follows the commits; others force at least that bump")
    parser.add_argument("--changelog", default="CHANGELOG.md")
    parser.add_argument("--date", default=datetime.date.today().isoformat())
    args = parser.parse_args()

    with open(args.changelog, encoding="utf-8") as f:
        text = f.read()
    current = re.search(rf"^## \[({VERSION}) ", text, re.M)
    if not current:
        log.fail("No released version found in CHANGELOG.md.")
    current = current.group(1)
    if subprocess.run(["git", "rev-parse", "-q", "--verify", f"refs/tags/{current}"], capture_output=True).returncode:
        log.fail(f"Tag '{current}' (latest version in CHANGELOG.md) does not exist.")

    level, notes = plan(commits(current), unreleased(text)["repo"])
    level = max(level, LEVELS[args.bump])
    if not level:
        return
    version = bumped(current, level)
    text = release(text, version, notes, args.date)
    with open(args.changelog, "w", encoding="utf-8") as f:
        f.write(text)
    print(version)


if __name__ == "__main__":
    main()
