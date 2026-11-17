#!/usr/bin/env python3
"""Run the checks in scripts/checks/ and the tests in scripts/tests/ (as test-<name>). Usage: python3 scripts/checks/run.py [mode|quick|all|list]"""
import os
import subprocess
import sys
from pathlib import Path

# The pipeline sets LOG_PREFIX to the job name; run on its own, lines say "Checks" and "Checks (<mode>)".
OUTER_PREFIX = os.environ.get("LOG_PREFIX")
os.environ["LOG_PREFIX"] = OUTER_PREFIX or "Checks"
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import log  # noqa: E402

CHECKS = Path(__file__).resolve().parent
ROOT = CHECKS.parents[1]
TESTS = CHECKS.parent / "tests"
QUICK = ["toc", "smoke", "changelog"]
AFTER_PACKAGE = ["worktree-clean"]


def scripts():
    found = {path.stem: path for path in CHECKS.glob("*.py") if path.name != "run.py"}
    found.update({f"test-{path.stem}": path for path in TESTS.glob("*.py")})
    return found


def modes():
    return sorted(scripts())


def run(mode):
    path = scripts()[mode]
    log.info(f"Running '{mode}'.")
    env = {**os.environ, "LOG_PREFIX": OUTER_PREFIX or f"Checks ({mode})"}
    return subprocess.run([sys.executable, str(path)], cwd=ROOT, env=env).returncode == 0


def main():
    os.chdir(ROOT)
    mode = sys.argv[1] if len(sys.argv) > 1 else "all"
    listed = [m for m in modes() if m not in AFTER_PACKAGE]
    if mode in ("-h", "--help", "help"):
        print("Usage: python3 scripts/checks/run.py [mode]")
        print("Modes:\n" + "\n".join(f"  - {m}" for m in modes()))
        print(f"Groups:\n  - quick ({' '.join(QUICK)})\n  - all (every mode except: {' '.join(AFTER_PACKAGE)})")
        print("Other:\n  - list (the modes 'all' runs, one per line)")
    elif mode == "list":
        print("\n".join(listed))
    elif mode in ("quick", "all"):
        failed = [m for m in (QUICK if mode == "quick" else listed) if not run(m)]
        if failed:
            log.fail(f"One or more modes failed: {', '.join(failed)}.")
    elif mode in modes():
        sys.exit(0 if run(mode) else 1)
    else:
        log.fail(f"Unknown mode '{mode}'. Use --help for available modes.")


if __name__ == "__main__":
    main()
