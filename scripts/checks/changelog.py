#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import log  # noqa: E402
from lib import changelog  # noqa: E402

version, date, _ = changelog.latest()
log.passed(f"Found version '{version}' with date '{date}' and non-empty release notes.")
