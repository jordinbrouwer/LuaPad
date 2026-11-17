#!/usr/bin/env python3
"""Compare the GitHub information (description, website) with the .toc and list what to change by hand.

GITHUB_TOKEN can't edit repository settings. Needs GH_TOKEN, GITHUB_REPOSITORY, GITHUB_SERVER_URL and GITHUB_SHA.
"""
import json
import os
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from lib import log  # noqa: E402
from lib import toc  # noqa: E402


def line_of(path, start):
    lines = Path(path).read_text(encoding="utf-8").splitlines()
    return next((i for i, line in enumerate(lines, 1) if line.lstrip().startswith(start)), 1)


def main():
    path = (toc.SRC / f"{toc.ADDON}.toc").as_posix()
    description, homepage = toc.field(path, "Notes"), toc.field(path, "X-Website")
    if not description or not homepage:
        log.error(f"{path} needs '## Notes:' and '## X-Website:' lines.")
    repo = os.environ["GITHUB_REPOSITORY"]
    current = json.loads(subprocess.run(
        ["gh", "repo", "view", repo, "--json", "description,homepageUrl"],
        check=True, capture_output=True, text=True,
    ).stdout)

    blob = f"{os.environ['GITHUB_SERVER_URL']}/{repo}/blob/{os.environ['GITHUB_SHA']}"
    rows = []
    if (current.get("description") or "") != description:
        rows.append(f"| Description | `{description}` ([{path}]({blob}/{path}#L{line_of(path, '## Notes:')})) |")
    if (current.get("homepageUrl") or "") != homepage:
        rows.append(f"| Website | {homepage} ([{path}]({blob}/{path}#L{line_of(path, '## X-Website:')})) |")

    if not rows:
        log.info("GitHub information matches the .toc.")
        return
    for row in rows:
        log.info(f"CHANGED: {row.split('|')[1].strip().lower()}")
    with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as out:
        out.write("### GitHub information update\n\n")
        out.write("| GitHub field | Update to |\n| --- | --- |\n" + "\n".join(rows) + "\n")
    log.warn("Update GitHub by hand", "See 'GitHub information update' in the summary of this run.")


if __name__ == "__main__":
    main()
