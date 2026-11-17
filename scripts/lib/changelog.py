"""Read the latest release section of CHANGELOG.md."""
import datetime
import re
from pathlib import Path

from lib import log

RELEASE = re.compile(r"^## \[(\d+\.\d+\.\d+)(?: \((\d{4}-\d{2}-\d{2})\))?\].*$", re.M)


def latest(path="CHANGELOG.md"):
    """(version, date, notes) of the newest release; fails if it is invalid."""
    path = Path(path)
    if not path.is_file():
        log.fail(f"{path} not found.")
    text = path.read_text(encoding="utf-8")
    if not re.search(r"^## \[Unreleased\]", text, re.M):
        log.fail("Missing Unreleased header.")
    releases = list(RELEASE.finditer(text))
    invalid = [m.group(0) for m in releases if not m.group(2)]
    if invalid:
        log.fail("Invalid release heading format detected.\n" + "\n".join(invalid))
    if not releases:
        log.fail("Missing first semantic version header.")
    first = releases[0]
    version, date = first.group(1), first.group(2)
    if date > datetime.date.today().isoformat():
        log.fail(f"First release date '{date}' is in the future.")
    end = releases[1].start() if len(releases) > 1 else len(text)
    notes = text[first.end():end].strip("\n").rstrip()
    if not notes.strip():
        log.fail("First version section is empty.")
    return version, date, notes
