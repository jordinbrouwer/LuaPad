#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/toc-lib.sh
source "$(dirname "$0")/../toc-lib.sh"

src_dir="$(toc_lib_src_dir)"

repo_files="$(
  find "$src_dir" -name '*.lua' -printf '%P\n' | sort
)"

reference_lua_files=""
toc_count=0

while IFS= read -r toc_file; do
  [ -n "$toc_file" ] || continue
  toc_count=$((toc_count + 1))
  toc_path="$src_dir/$toc_file"

  if ! git ls-files --error-unmatch "$toc_path" >/dev/null 2>&1; then
    echo "[TOC CHECK] FAILED: $toc_path exists but is not tracked by git."
    exit 1
  fi

  version_line_count="$(grep -Ec '^## Version: ' "$toc_path" || true)"
  if [ "$version_line_count" -ne 1 ]; then
    echo "[TOC CHECK] FAILED: Expected exactly one '## Version:' line in $toc_path, found $version_line_count."
    exit 1
  fi

  if ! toc_lib_interface_csv "$toc_path" >/dev/null; then
    exit 1
  fi

  toc_lua_files="$(toc_lib_lua_files "$toc_path")"
  duplicates="$(printf '%s\n' "$toc_lua_files" | uniq -d)"
  if [ -n "$duplicates" ]; then
    echo "[TOC CHECK] FAILED: $toc_path lists Lua files more than once:"
    echo "$duplicates"
    exit 1
  fi

  if [ -z "$reference_lua_files" ]; then
    reference_lua_files="$toc_lua_files"
  elif [ "$toc_lua_files" != "$reference_lua_files" ]; then
    echo "[TOC CHECK] FAILED: Lua file lists differ between TOC files."
    echo "[TOC CHECK] Expected all TOCs to list the same Lua files."
    echo "[TOC CHECK] Reference from $(toc_lib_discover | head -n 1):"
    echo "$reference_lua_files"
    echo "[TOC CHECK] Mismatch in $toc_path:"
    echo "$toc_lua_files"
    exit 1
  fi
done < <(toc_lib_discover)

if [ "$toc_count" -eq 0 ]; then
  echo "[TOC CHECK] FAILED: No TOC files found."
  exit 1
fi

if [ "$reference_lua_files" != "$repo_files" ]; then
  echo "[TOC CHECK] FAILED: TOC and '$src_dir' Lua file lists differ."
  diff <(echo "$reference_lua_files") <(echo "$repo_files") \
    --old-line-format='  only in TOC:      %L' \
    --new-line-format="  only in $src_dir/: %L" \
    --unchanged-line-format='' || true
  exit 1
fi

echo "[TOC CHECK] PASSED: ${toc_count} TOC file(s), Lua file list, and version lines look valid."
