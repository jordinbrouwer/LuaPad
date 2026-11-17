#!/usr/bin/env python3
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import log  # noqa: E402

scripts = sorted(Path("scripts").rglob("*.py"))
failed = []
for path in scripts:
    try:
        compile(path.read_text(encoding="utf-8"), str(path), "exec")
    except SyntaxError as error:
        log.info(f"{path}:{error.lineno}: {error.msg}")
        failed.append(path)
if failed:
    log.fail(f"{len(failed)} script(s) do not compile.")
log.passed(f"{len(scripts)} script(s) compile.")
