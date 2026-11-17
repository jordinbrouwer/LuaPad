#!/usr/bin/env python3
import os
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import log  # noqa: E402

tmp = Path(".tmp")
tmp.mkdir(exist_ok=True)
for old in tmp.glob("*.zip"):
    old.unlink()
with tempfile.NamedTemporaryFile("r", suffix=".txt") as output:
    ref = os.environ.get("GITHUB_REF", "refs/heads/local")
    ref_name = os.environ.get("GITHUB_REF_NAME", "local")
    if subprocess.run([sys.executable, "scripts/build-package.py", output.name, ref, ref_name]).returncode:
        sys.exit(1)
    values = dict(line.split("=", 1) for line in Path(output.name).read_text().splitlines() if "=" in line)
for key in ("version", "archive_version", "archive_path", "notes_path"):
    if not values.get(key):
        log.fail(f"Missing required output key '{key}'.")
for key in ("notes_path", "archive_path"):
    path = Path(values[key])
    if not path.is_file() or not path.stat().st_size:
        log.fail(f"{key} output is missing or empty.")
zips = list(tmp.glob("*.zip"))
if len(zips) != 1:
    log.fail(f"Expected exactly 1 zip in .tmp, found {len(zips)}.")
log.passed("build-package.py output contract is valid.")
