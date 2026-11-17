#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/toc-lib.sh
source "$(dirname "$0")/../toc-lib.sh"

src_dir="$(toc_lib_src_dir)"
icon_file="$src_dir/$(toc_lib_addon_basename).tga"

if [ ! -f "$icon_file" ]; then
  echo "[SMOKE CHECK] FAILED: Missing $icon_file."
  exit 1
fi

missing=0
toc_count=0

while IFS= read -r toc_file; do
  [ -n "$toc_file" ] || continue
  toc_count=$((toc_count + 1))
  toc_path="$src_dir/$toc_file"

  if [ ! -f "$toc_path" ]; then
    echo "[SMOKE CHECK] FAILED: Missing $toc_path."
    exit 1
  fi

  while IFS= read -r file; do
    [ -n "$file" ] || continue
    if [ ! -f "$src_dir/$file" ]; then
      echo "[SMOKE CHECK] FAILED: $toc_path references missing Lua file: $src_dir/$file"
      missing=1
    fi
  done < <(toc_lib_lua_files "$toc_path")
done < <(toc_lib_discover)

if [ "$toc_count" -eq 0 ]; then
  echo "[SMOKE CHECK] FAILED: No TOC files found."
  exit 1
fi

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "[SMOKE CHECK] PASSED: Required addon files and ${toc_count} TOC file(s) look valid."
