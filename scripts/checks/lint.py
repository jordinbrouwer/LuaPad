#!/usr/bin/env python3
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import log  # noqa: E402
from lib import toc  # noqa: E402

if not shutil.which("luacheck"):
    log.fail("luacheck is required.")
if not any(toc.SRC.rglob("*.lua")):
    log.fail(f"No Lua files found in '{toc.SRC}'.")
if log.run("luacheck", "--no-color", str(toc.SRC)):
    log.fail("Luacheck found problems.")
log.passed("Luacheck completed successfully.")
