#!/usr/bin/env python3
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import log  # noqa: E402
from lib import toc  # noqa: E402

repo_files = sorted(p.relative_to(toc.SRC).as_posix() for p in toc.SRC.rglob("*.lua"))
tocs = toc.discover()
reference = None
for name in tocs:
    path = toc.SRC / name
    if subprocess.run(["git", "ls-files", "--error-unmatch", str(path)], capture_output=True).returncode:
        log.fail(f"{path} exists but is not tracked by git.")
    versions = len(re.findall(r"^## Version: ", path.read_text(encoding="utf-8"), re.M))
    if versions != 1:
        log.fail(f"Expected exactly one '## Version:' line in {path}, found {versions}.")
    toc.interfaces(path)
    files = toc.lua_files(path)
    duplicates = sorted({f for f in files if files.count(f) > 1})
    if duplicates:
        log.fail(f"{path} lists Lua files more than once:\n" + "\n".join(duplicates))
    if reference is None:
        reference = files
    elif files != reference:
        log.fail(
            "Lua file lists differ between TOC files.\n"
            f"Reference from {tocs[0]}:\n" + "\n".join(reference)
            + f"\nMismatch in {path}:\n" + "\n".join(files)
        )
if reference != repo_files:
    lines = [f"  only in TOC:      {f}" for f in reference if f not in repo_files]
    lines += [f"  only in {toc.SRC}/: {f}" for f in repo_files if f not in reference]
    log.fail(f"TOC and '{toc.SRC}' Lua file lists differ.\n" + "\n".join(lines))
log.passed(f"{len(tocs)} TOC file(s), Lua file list, and version lines look valid.")
