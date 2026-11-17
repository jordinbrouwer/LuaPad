#!/usr/bin/env python3
"""List what has to change on CurseForge since the previous release.

Usage: compare.py <tag>
Prints "[<prefix>] CHANGED: readme | description | license | media <A|M|D> <file>" lines.
"""
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import log  # noqa: E402
from lib import toc  # noqa: E402
from lib.readme import without_block  # noqa: E402

TOC = (toc.SRC / f"{toc.ADDON}.toc").as_posix()
ICON = (toc.SRC / f"{toc.ADDON}.tga").as_posix()


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True)


def show(ref, path):
    return git("show", f"{ref}:{path}").stdout


def notes(text):
    match = re.search(r"^## Notes:[ \t]*(.*)$", text, re.M)
    return match.group(1).strip() if match else ""


def main():
    if len(sys.argv) != 2:
        log.fail("Usage: compare.py <tag>")
    ref = sys.argv[1]
    previous = git("describe", "--tags", "--abbrev=0", "--match", "[0-9]*.[0-9]*.[0-9]*", f"{ref}^").stdout.strip()
    if not previous:
        log.info("CHANGED: readme (first release)")
        return

    images_changed = git("diff", "--quiet", previous, ref, "--", "docs/images").returncode
    if images_changed or without_block(show(previous, "README.md")) != without_block(show(ref, "README.md")):
        log.info(f"CHANGED: readme (README.md or docs/images changed since {previous})")
    else:
        log.info(f"README.md and docs/images unchanged since {previous}; README on CurseForge is up to date.")

    if notes(show(previous, TOC)) != notes(show(ref, TOC)):
        log.info(f"CHANGED: description (.toc Notes changed since {previous})")

    license_name = show(ref, "LICENSE").split("\n", 1)[0]
    if show(previous, "LICENSE").split("\n", 1)[0] != license_name:
        log.info(f"CHANGED: license (LICENSE changed to '{license_name}' since {previous})")

    for line in git("diff", "--name-status", previous, ref, "--", "docs/images", ICON).stdout.splitlines():
        status, path = line.split("\t", 1)
        log.info(f"CHANGED: media {status} {path}")


if __name__ == "__main__":
    main()
