#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/toc-lib.sh
source "$(dirname "$0")/../toc-lib.sh"

if ! command -v luacheck >/dev/null 2>&1; then
  echo "[LINT CHECK] FAILED: luacheck is required."
  exit 1
fi

src_dir="$(toc_lib_src_dir)"
if [ -z "$(find "$src_dir" -name '*.lua' -print -quit)" ]; then
  echo "[LINT CHECK] FAILED: No Lua files found in '$src_dir'."
  exit 1
fi

luacheck "$src_dir"
echo "[LINT CHECK] PASSED: Luacheck completed successfully."
