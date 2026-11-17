#!/usr/bin/env bash
# CurseForge has no API for the project description, so this builds it from
# README.md and warns when it has to be pasted into CurseForge again.
set -euo pipefail

ref="${1:-}"
output_file="${2:-}"
if [ -z "$ref" ] || [ -z "$output_file" ]; then
  echo "[DESCRIPTION] FAILED: Usage: curseforge-description.sh <tag> <output_file>"
  exit 1
fi

repo_url="$(sed -nE 's|^## \[Unreleased\]\((https://github\.com/[^/]+/[^/)]+)/compare/.*|\1|p' CHANGELOG.md)"
if [ -z "$repo_url" ]; then
  echo "[DESCRIPTION] FAILED: Could not read the repository URL from the Unreleased link in CHANGELOG.md."
  exit 1
fi
raw_url="${repo_url/github.com/raw.githubusercontent.com}/$ref"
blob_url="$repo_url/blob/$ref"

# Relative images point at the raw file of this tag, other relative links at the file on GitHub.
mkdir -p "$(dirname "$output_file")"
sed -E \
  -e "s|(src=\")([^\":]+\")|\1$raw_url/\2|g" \
  -e "s|(!\[[^]]*\]\()([^):]+\))|\1$raw_url/\2|g" \
  -e "s|(\]\()([^)#:][^):]*\))|\1$blob_url/\2|g" \
  README.md > "$output_file"
echo "[DESCRIPTION] Wrote '$output_file' from README.md."

previous="$(git describe --tags --abbrev=0 --match '[0-9]*.[0-9]*.[0-9]*' "$ref^" 2>/dev/null || true)"
if [ -z "$previous" ]; then
  echo "::warning title=Update the CurseForge description::First release: paste curseforge-description.md (attached to the release) into the CurseForge description."
  exit 0
fi

# Images are linked by tag, so new images also need a new paste.
if git diff --quiet "$previous" "$ref" -- README.md docs/images; then
  echo "[DESCRIPTION] README.md and docs/images unchanged since $previous; CurseForge description is up to date."
else
  echo "::warning title=Update the CurseForge description::README.md or docs/images changed since $previous. Paste curseforge-description.md (attached to the release) into the CurseForge description."
fi

toc="src/LuaPad.toc"
notes_at() {
  git show "$1:$toc" | sed -nE 's/^## Notes:[[:space:]]*//p'
}
if [ "$(notes_at "$previous")" != "$(notes_at "$ref")" ]; then
  echo "::warning title=Update the CurseForge summary::The .toc Notes line changed since $previous. Set the CurseForge summary to: $(notes_at "$ref")"
fi
