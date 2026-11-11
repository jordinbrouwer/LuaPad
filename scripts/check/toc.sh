#!/usr/bin/env bash
# Every file listed in the .toc must exist.
set -euo pipefail
cd "$(dirname "$0")/../../src"
status=0
while IFS= read -r line; do
  line="${line%$'\r'}"
  [[ -z "$line" || "$line" == \#* ]] && continue
  if [[ ! -f "$line" ]]; then
    echo "Missing file in TOC: src/$line"
    status=1
  fi
done < LuaPad.toc
exit $status
