#!/usr/bin/env python3
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import log  # noqa: E402

SCRIPT = Path(__file__).resolve().parents[1] / "next-version.py"


fail = log.fail


with tempfile.TemporaryDirectory() as tmp:
    repo = Path(tmp)

    def git(*args):
        return subprocess.run(["git", "-C", tmp, "-c", "user.name=check", "-c", "user.email=check@example.com", *args],
                              check=True, capture_output=True, text=True).stdout.strip()

    def commit(message, *extra):
        git("commit", "-q", "--allow-empty", "-m", message, *extra)

    def src_commit(message):
        (repo / "src").mkdir(exist_ok=True)
        with open(repo / "src" / "a.lua", "a") as f:
            f.write(message + "\n")
        git("add", "src")
        commit(message)
        return git("rev-parse", "HEAD")

    def nxt(*args):
        run = subprocess.run([sys.executable, str(SCRIPT), "--date", "2026-01-02", *args], cwd=tmp, capture_output=True, text=True)
        return run.returncode, run.stdout.strip()

    git("init", "-q")
    (repo / "CHANGELOG.md").write_text(
        "# Changelog\n\n## [Unreleased](https://github.com/o/r/compare/1.0.0...main)\n\n### Changed\n- Written by hand.\n\n"
        "## [1.0.0 (2026-01-01)](https://github.com/o/r/releases/tag/1.0.0)\n\nFirst release.\n"
    )
    git("add", "CHANGELOG.md")
    commit("chore: init")
    git("tag", "1.0.0")

    feat = src_commit("feat(ui): add dark mode")
    fix = src_commit("fix: crash on load")
    commit("docs: typo")
    commit("chore: tidy")

    if nxt() != (0, "1.1.0"):
        fail("feat + fix should release 1.1.0.")
    changelog = (repo / "CHANGELOG.md").read_text()
    expected = (
        "## [Unreleased](https://github.com/o/r/compare/1.1.0...main)\n\n"
        "## [1.1.0 (2026-01-02)](https://github.com/o/r/releases/tag/1.1.0)\n\n"
        f"### Added\n- Add dark mode. ([{feat[:7]}](https://github.com/o/r/commit/{feat}))\n\n"
        "### Changed\n- Written by hand.\n\n"
        f"### Fixed\n- Crash on load. ([{fix[:7]}](https://github.com/o/r/commit/{fix}))\n\n"
        "## [1.0.0 (2026-01-01)]"
    )
    if expected not in changelog:
        fail(f"Unexpected CHANGELOG.md:\n{changelog}")
    if "Typo" in changelog or "Tidy" in changelog:
        fail("docs/chore commits must not be listed.")

    commit("chore(release): 1.1.0", "-a")
    git("tag", "1.1.0")
    commit("ci: nothing to release")
    if nxt() != (0, ""):
        fail("Only ci/chore commits should not release.")
    if nxt("--bump", "patch")[0] == 0:
        fail("A forced bump with empty release notes should fail.")

    commit("feat: outside src only")
    if nxt() != (0, ""):
        fail("Commits that do not touch src/ should not release.")

    src_commit("feat!: drop the old API")
    if nxt() != (0, "2.0.0"):
        fail("A breaking change should release 2.0.0.")

log.passed("Version bumps and changelog sections follow the commits.")
