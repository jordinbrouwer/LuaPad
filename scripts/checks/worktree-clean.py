#!/usr/bin/env python3
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import log  # noqa: E402


def git(*args):
    return subprocess.run(["git", *args], capture_output=True).returncode


if git("rev-parse", "--is-inside-work-tree"):
    log.fail("Run this script inside a git repository.")
if git("diff", "--quiet", "--exit-code"):
    log.fail("Tracked working tree has unexpected changes.")
if git("diff", "--cached", "--quiet", "--exit-code"):
    log.fail("Index has staged tracked changes.")
log.passed("Tracked working tree and index are clean.")
