"""Log lines with one prefix: the pipeline job (LOG_PREFIX, like [Checks (toc)]), or the script path when run on its own."""
import os
import subprocess
import sys
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1]


def _name():
    path = Path(sys.argv[0]).resolve()
    return path.relative_to(SCRIPTS).with_suffix("").as_posix() if path.is_relative_to(SCRIPTS) else path.stem


PREFIX = f"[{os.environ.get('LOG_PREFIX') or _name()}]"


def info(message):
    print(f"{PREFIX} {message}", flush=True)


def passed(message):
    info(f"PASSED: {message}")


def fail(message):
    info(f"FAILED: {message}")
    sys.exit(1)


def run(*command):
    """Run a tool and log its output with the prefix; returns the exit code."""
    result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    for line in result.stdout.splitlines():
        if line.strip():
            info(line.rstrip())
    return result.returncode


def warn(title, message):
    print(f"::warning title={title}::{PREFIX} {message}", flush=True)


def error(message):
    print(f"::error::{PREFIX} {message}", flush=True)
    sys.exit(1)
