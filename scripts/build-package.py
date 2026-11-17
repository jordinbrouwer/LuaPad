#!/usr/bin/env python3
"""Build the addon zip from src/ and the release notes from CHANGELOG.md.

Usage: build-package.py <output_file> <github_ref> <github_ref_name>
Writes version, archive_version, archive_path and notes_path to <output_file> (key=value lines).
"""
import datetime
import io
import os
import re
import subprocess
import sys
import tarfile
import tempfile
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lib import log  # noqa: E402
from lib import changelog, toc  # noqa: E402


fail = log.fail


def git(*args):
    return subprocess.run(["git", *args], check=True, capture_output=True).stdout


def main():
    if len(sys.argv) < 2 or not sys.argv[1]:
        fail("Missing output file argument.")
    output_file = Path(sys.argv[1])
    ref = sys.argv[2] if len(sys.argv) > 2 else ""
    ref_name = sys.argv[3] if len(sys.argv) > 3 else ""
    output_file.write_text("")
    if subprocess.run(["git", "rev-parse", "--is-inside-work-tree"], capture_output=True).returncode:
        fail("Run this script inside the repository.")

    version, _, notes = changelog.latest()
    notes_path = Path(os.environ.get("RELEASE_NOTES_PATH", ".tmp/release-notes.md"))
    notes_path.parent.mkdir(parents=True, exist_ok=True)
    notes_path.write_text(notes + "\n", encoding="utf-8")

    is_tag = ref.startswith("refs/tags/")
    if is_tag:
        if not re.fullmatch(r"\d+\.\d+\.\d+", ref_name):
            fail(f"Tag '{ref_name}' is not supported (expected 1.2.3).")
        if ref_name != version:
            fail(f"Tag version '{ref_name}' does not match changelog version '{version}'.")

    suffix = os.environ.get("RELEASE_ARCHIVE_SUFFIX", "")
    if not suffix and not is_tag and os.environ.get("CI") != "true":
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        suffix = f"{stamp}-{git('rev-parse', '--short', 'HEAD').decode().strip()}"
    archive_version = f"{version}-{suffix}" if suffix else version
    archive_path = Path(".tmp") / f"{toc.ADDON}-{archive_version}.zip"
    archive_path.parent.mkdir(exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        tar = git("archive", "--format=tar", f"--prefix={toc.ADDON}/", f"HEAD:{toc.SRC}")
        with tarfile.open(fileobj=io.BytesIO(tar)) as archive:
            archive.extractall(tmp, filter="data")
        addon_dir = Path(tmp) / toc.ADDON
        tocs = toc.discover(addon_dir)
        for name in tocs:
            toc.set_version(addon_dir / name, version)

        archive_path.unlink(missing_ok=True)
        with zipfile.ZipFile(archive_path, "w", zipfile.ZIP_DEFLATED) as zipped:
            for path in [addon_dir, *sorted(addon_dir.rglob("*"))]:
                zipped.write(path, path.relative_to(tmp).as_posix())
        with zipfile.ZipFile(archive_path) as zipped:
            files = set(zipped.namelist())

        required = [f"{toc.ADDON}/{toc.ADDON}.tga"] + [f"{toc.ADDON}/{name}" for name in tocs]
        required += [f"{toc.ADDON}/{lua}" for name in tocs for lua in toc.lua_files(addon_dir / name)]
        for path in required:
            if path not in files:
                fail(f"Archive missing required file '{path}'.")
    for disallowed in (".github/", "scripts/", ".luacheckrc"):
        if any(f.startswith(f"{toc.ADDON}/{disallowed}") for f in files):
            fail(f"Archive includes dev-only path '{toc.ADDON}/{disallowed}'.")

    with open(output_file, "a", encoding="utf-8") as out:
        out.write(f"version={version}\narchive_version={archive_version}\narchive_path={archive_path}\nnotes_path={notes_path}\n")
    log.passed(f"Created '{archive_path}' with version '{archive_version}' ({len(tocs)} TOC file(s)).")


if __name__ == "__main__":
    main()
