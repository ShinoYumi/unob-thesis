#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
ROOT="${ROOT:-$(cd -- "$SCRIPT_DIR/.." && pwd -P)}"
TT="${TT:-$ROOT/.tools/tt}"
FONT_PATH="${FONT_PATH:-$ROOT/resources/fonts}"
if [[ -n "${TT_FONT_ARGS:-}" ]]; then
  # shellcheck disable=SC2206
  TT_FONT_ARGS_ARR=($TT_FONT_ARGS)
else
  TT_FONT_ARGS_ARR=(--font-path "$FONT_PATH" --use-system-fonts)
fi

if [[ ! -x "$TT" ]]; then
  echo "ERROR: tytanic binary not found: $TT"
  exit 2
fi

"$TT" update --root "$ROOT" "${TT_FONT_ARGS_ARR[@]}" --no-skip --force -e 'persistent() & r:^phase/'
echo "Updated persistent references for phase tests."
