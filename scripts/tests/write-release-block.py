#!/usr/bin/env python3
import re
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import log  # noqa: E402

SCRIPT = Path(__file__).resolve().parents[1] / "curseforge-information" / "write-release-block.py"


fail = log.fail


readme_text = Path("README.md").read_text(encoding="utf-8")
if not (re.search(r"^<!-- release:start -->$", readme_text, re.M) and re.search(r"^<!-- release:end -->$", readme_text, re.M)):
    fail("README.md needs the release markers.")

with tempfile.TemporaryDirectory() as tmp:
    readme, notes = Path(tmp) / "README.md", Path(tmp) / "notes.md"
    readme.write_text("# App\n\nIntro.\n\n<!-- release:start -->\nold\n<!-- release:end -->\n\n## Usage\n")
    notes.write_text("### Added\n- Add dark mode. ([a1b2c3d](https://github.com/o/r/commit/a1b2c3d))\n")

    def run(*extra):
        subprocess.run([sys.executable, str(SCRIPT), "--readme", str(readme), "--notes", str(notes), "--version", "1.1.0",
                        "--date", "2026-01-02", "--repo", "https://github.com/o/r", "--website", "https://cf.example/app", *extra],
                       check=True, capture_output=True)

    run("--project-id", "123")
    text = readme.read_text()
    for want in ("curseforge/v/123", "github/v/release/o/r", "**Latest release: [1.1.0](https://github.com/o/r/releases/tag/1.1.0)** (2026-01-02)",
                 "**Added**", "- Add dark mode.", "## Usage"):
        if want not in text:
            fail(f"Missing '{want}' in:\n{text}")
    if "old" in text:
        fail("The old release block was not replaced.")

    run()
    text = readme.read_text()
    if text.count("release:start") != 1:
        fail("The release block was duplicated.")
    if "curseforge/v/" in text:
        fail("No project ID should mean no CurseForge badges.")

log.passed("The README release block is written from the release notes.")
