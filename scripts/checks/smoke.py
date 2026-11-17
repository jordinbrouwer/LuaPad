#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import log  # noqa: E402
from lib import toc  # noqa: E402

icon = toc.SRC / f"{toc.ADDON}.tga"
if not icon.is_file():
    log.fail(f"Missing {icon}.")
tocs = toc.discover()
missing = [
    f"{toc.SRC / name} references missing Lua file: {toc.SRC / lua}"
    for name in tocs
    for lua in toc.lua_files(toc.SRC / name)
    if not (toc.SRC / lua).is_file()
]
if missing:
    log.fail("\n".join(missing))
log.passed(f"Required addon files and {len(tocs)} TOC file(s) look valid.")
