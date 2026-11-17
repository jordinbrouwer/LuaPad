#!/usr/bin/env python3
"""Write README.md for the CurseForge Description field: no release block, links pointing at the tag on GitHub.

Usage: write-readme.py <tag> <output_file>
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib import log  # noqa: E402
from lib.readme import without_block  # noqa: E402


def for_curseforge(text, raw, blob):
    text = without_block(text)
    text = re.sub(r'(src=")(?:\.?/)?([^":]+")', rf"\g<1>{raw}/\g<2>", text)
    text = re.sub(r"(!\[[^\]]*\]\()(?:\.?/)?([^):]+\))", rf"\g<1>{raw}/\g<2>", text)
    return re.sub(r"(?<!!)(\[[^\]]*\]\()(?:\.?/)?([^)#:][^):]*\))", rf"\g<1>{blob}/\g<2>", text)


def main():
    if len(sys.argv) != 3:
        log.fail("Usage: write-readme.py <tag> <output_file>")
    ref, output = sys.argv[1], Path(sys.argv[2])
    match = re.search(r"^## \[Unreleased\]\((https://github\.com/[^/]+/[^/)]+)/compare/", Path("CHANGELOG.md").read_text(), re.M)
    if not match:
        log.fail("Could not read the repository URL from the Unreleased link in CHANGELOG.md.")
    repo = match.group(1)
    raw = f"{repo.replace('github.com', 'raw.githubusercontent.com')}/{ref}"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(for_curseforge(Path("README.md").read_text(encoding="utf-8"), raw, f"{repo}/blob/{ref}"), encoding="utf-8")
    log.info(f"Wrote '{output}' from README.md.")


if __name__ == "__main__":
    main()
