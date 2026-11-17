#!/usr/bin/env bash
set -euo pipefail

script="$PWD/scripts/next-release.py"
repo="$(mktemp -d)"
trap 'rm -rf "$repo"' EXIT INT TERM

fail() {
  echo "[NEXT RELEASE CHECK] FAILED: $1"
  exit 1
}

commit() {
  git -C "$repo" -c user.name=check -c user.email=check@example.com commit -q --allow-empty -m "$1" "${@:2}"
}

# Commits that change the shipped addon in src/.
src_commit() {
  mkdir -p "$repo/src"
  echo "$1" >> "$repo/src/a.lua"
  git -C "$repo" add src
  commit "$1"
}

next() {
  (cd "$repo" && python3 "$script" --date 2026-01-02 "$@")
}

git -C "$repo" init -q
cat > "$repo/CHANGELOG.md" <<'EOF'
# Changelog

## [Unreleased](https://github.com/o/r/compare/1.0.0...main)

### Changed
- Written by hand.

## [1.0.0 (2026-01-01)](https://github.com/o/r/releases/tag/1.0.0)

First release.
EOF
git -C "$repo" add CHANGELOG.md
commit "chore: init"
git -C "$repo" tag 1.0.0

src_commit "feat(ui): add dark mode"
feat="$(git -C "$repo" rev-parse HEAD)"
src_commit "fix: crash on load"
fix="$(git -C "$repo" rev-parse HEAD)"
commit "docs: typo"
commit "chore: tidy"

[ "$(next)" = "1.1.0" ] || fail "feat + fix should release 1.1.0."
changelog="$(cat "$repo/CHANGELOG.md")"
expected="## [Unreleased](https://github.com/o/r/compare/1.1.0...main)

## [1.1.0 (2026-01-02)](https://github.com/o/r/releases/tag/1.1.0)

### Added
- Add dark mode. ([${feat:0:7}](https://github.com/o/r/commit/$feat))

### Changed
- Written by hand.

### Fixed
- Crash on load. ([${fix:0:7}](https://github.com/o/r/commit/$fix))

## [1.0.0 (2026-01-01)]"
[[ "$changelog" == *"$expected"* ]] || fail "Unexpected CHANGELOG.md:
$changelog"
case "$changelog" in *Typo*|*Tidy*) fail "docs/chore commits must not be listed." ;; esac

commit "chore(release): 1.1.0" -a
git -C "$repo" tag 1.1.0
commit "ci: nothing to release"
[ -z "$(next)" ] || fail "Only ci/chore commits should not release."
if next --bump patch >/dev/null 2>&1; then
  fail "A forced bump with empty release notes should fail."
fi

commit "feat: outside src only"
[ -z "$(next)" ] || fail "Commits that do not touch src/ should not release."

src_commit "feat!: drop the old API"
[ "$(next)" = "2.0.0" ] || fail "A breaking change should release 2.0.0."

echo "[NEXT RELEASE CHECK] PASSED: Version bumps and changelog sections follow the commits."
